import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/knowledge_manifest.dart';

/// 简单的模块下载管理器
/// 功能：
/// - 支持断点续传（使用 HTTP Range）
/// - 支持简单的分片/续传策略（检查已有文件长度并请求剩余数据）
/// - 支持 SHA256 校验
/// - 支持进度回调和重试（指数退避）
/// - 返回最终已写入的文件
class DownloadManager {
  DownloadManager._internal();
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;

  final Dio _dio = Dio()
    ..options = BaseOptions(connectTimeout: const Duration(seconds: 30));

  /// 最大重试次数
  int maxRetries = 5;

  /// 基本重试延迟（毫秒）
  int baseDelayMs = 500;

  /// 下载一个模块到本地缓存目录，返回最终文件
  /// onProgress(progress) : progress 0.0-1.0
  Future<File> downloadModule(
    KnowledgeModule module, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final modulesDir = Directory(p.join(dir.path, 'modules'));
    if (!await modulesDir.exists()) await modulesDir.create(recursive: true);

    final filename = '${module.id}_${module.version}.${_inferExtension(module)}';
    final tempFile = File(p.join(modulesDir.path, '\$filename.part'));
    final finalFile = File(p.join(modulesDir.path, filename));

    // 如果最终文件已存在且校验通过，直接返回
    if (await finalFile.exists()) {
      final ok = await _verifyChecksum(finalFile, module.checksum);
      if (ok) return finalFile;
      // 校验失败则删除并重新下载
      await finalFile.delete();
    }

    int attempt = 0;
    while (true) {
      try {
        int existing = 0;
        if (await tempFile.exists()) {
          existing = await tempFile.length();
        } else {
          await tempFile.create(recursive: true);
        }

        // HEAD 请求尝试获取总大小（如果服务器支持）
        int? totalSize;
        try {
          final headResp = await _dio.head(module.downloadUrl,
              options: Options(receiveTimeout: const Duration(seconds: 10)));
          if (headResp.headers.value(HttpHeaders.contentLengthHeader) != null) {
            totalSize = int.tryParse(headResp.headers.value(HttpHeaders.contentLengthHeader)!);
          }
        } catch (_) {
          // 忽略 HEAD 错误，继续使用 GET
        }

        final headers = <String, dynamic>{};
        if (existing > 0) {
          headers[HttpHeaders.rangeHeader] = 'bytes=\$existing-';
        }

        final response = await _dio.get<ResponseBody>(
          module.downloadUrl,
          options: Options(
            responseType: ResponseType.stream,
            headers: headers,
          ),
          cancelToken: cancelToken,
        );

        // 如果服务器返回 416 或 200 without support for Range, handle accordingly
          if (response.statusCode == 416) {
          // Range not satisfiable — maybe file already complete
          if (await tempFile.exists()) {
            await tempFile.rename(finalFile.path);
            if (await _verifyChecksum(finalFile, module.checksum)) return finalFile;
            // 否则继续重新下载
            try {
              await finalFile.delete();
            } catch (_) {}
            existing = 0;
          }
        }

        final stream = response.data!.stream;
        final sink = tempFile.openWrite(mode: FileMode.append);

        int downloaded = existing;
        final completer = Completer<File>();

        stream.listen((Uint8List chunk) async {
          // 写入数据
          sink.add(chunk);
          downloaded += chunk.length;
          if (totalSize != null) {
            final progress = totalSize > 0 ? downloaded / totalSize : 0.0;
            if (onProgress != null) onProgress(progress.clamp(0.0, 1.0));
          } else {
            // 当 totalSize 不可用时，返回 null/unknown 进度
            if (onProgress != null) onProgress(0.0);
          }
        }, onDone: () async {
          await sink.close();
          // 重命名为最终文件并校验
          await tempFile.rename(finalFile.path);
          final ok = await _verifyChecksum(finalFile, module.checksum);
          if (ok) {
            completer.complete(finalFile);
          } else {
            // 校验失败，删除并抛出异常以触发重试
            try {
              await finalFile.delete();
            } catch (_) {}
            completer.completeError(StateError('Checksum mismatch'));
          }
        }, onError: (e) async {
          await sink.close();
          completer.completeError(e);
        }, cancelOnError: true);

        final result = await completer.future;
        return result;
      } catch (e) {
        attempt++;
        if (attempt > maxRetries) rethrow;
        final delayMs = baseDelayMs * (1 << (attempt - 1));
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  String _inferExtension(KnowledgeModule module) {
    final fmt = module.format.toLowerCase();
    if (fmt.contains('zip')) return 'zip';
    if (fmt.contains('json')) return 'json';
    if (fmt.contains('audio')) return 'zip';
    return 'dat';
  }

  Future<bool> _verifyChecksum(File file, String expected) async {
    try {
      // expected may be like "sha256:abcd..." or plain hex
      var expectedHex = expected;
      if (expected.startsWith('sha256:')) {
        expectedHex = expected.substring('sha256:'.length);
      }
      final actualHex = await _computeFileSha256(file);
      return actualHex.toLowerCase() == expectedHex.toLowerCase();
    } catch (e) {
      return false;
    }
  }

  /// 公共方法：验证本地文件的sha256，返回是否匹配
  Future<bool> verifyFileChecksum(File file, String expected) async {
    return _verifyChecksum(file, expected);
  }

  /// 获取模块目录
  Future<Directory> _getModulesDir() async {
    final dir = await getApplicationSupportDirectory();
    final modulesDir = Directory(p.join(dir.path, 'modules'));
    if (!await modulesDir.exists()) await modulesDir.create(recursive: true);
    return modulesDir;
  }

  /// 获取模块的最终文件（如果存在），不触发下载
  Future<File> getLocalModuleFile(KnowledgeModule module) async {
    final modulesDir = await _getModulesDir();
    final filename = '${module.id}_${module.version}.${_inferExtension(module)}';
    return File(p.join(modulesDir.path, filename));
  }

  Future<String> _computeFileSha256(File file) async {
    // 为了实现简单可靠地计算校验，这里先读取完整文件并计算sha256。
    // 如果模块文件非常大（GB级），可改为分块计算以节省内存。
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

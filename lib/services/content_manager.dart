import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../models/embedding.dart';
import '../models/module_metadata.dart';
import 'local_storage_service.dart';
import 'module_state_service.dart';

/// 模块内容管理器
/// - 负责解压和读取模块文件
/// - 管理媒体文件的存储位置
/// - 提供资源访问接口
class ContentManager {
  static final ContentManager _instance = ContentManager._internal();
  factory ContentManager() => _instance;
  ContentManager._internal();

  final _storage = LocalStorageService();
  Directory? _mediaDir;

  /// 初始化
  Future<void> initialize() async {
    final appDir = await getApplicationSupportDirectory();
    _mediaDir = Directory(p.join(appDir.path, 'media'));
    if (!await _mediaDir!.exists()) {
      await _mediaDir!.create(recursive: true);
    }
  }

  /// 导入模块文件
  Future<void> importModule(File moduleFile, ModuleMetadata metadata) async {
    if (!await moduleFile.exists()) {
      throw Exception('模块文件不存在');
    }

    // 1. 创建模块目录
    final moduleDir = Directory(p.join(_mediaDir!.path, metadata.id));
    if (await moduleDir.exists()) {
      await moduleDir.delete(recursive: true);
    }
    await moduleDir.create();

    // 2. 解压模块文件
    final bytes = await moduleFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 3. 提取文件
    final embeddings = <Embedding>[];
    for (final file in archive) {
      if (file.isFile) {
        // 3.1 解析文件名和类型
        final filename = file.name;
        if (filename.endsWith('.json') && filename.contains('embeddings')) {
          // 处理向量文件
          final content = String.fromCharCodes(file.content as List<int>);
          final json = const JsonDecoder().convert(content) as List;
          embeddings.addAll(json.map((e) => Embedding.fromJson(e as Map<String, dynamic>)));
        } else {
          // 处理媒体文件
          final outFile = File(p.join(moduleDir.path, filename));
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }
    }

    // 4. 保存向量到数据库
    if (embeddings.isNotEmpty) {
      await _storage.insertEmbeddings(embeddings);
    }

    // 5. 更新模块状态
    await _updateModuleState(metadata, moduleDir);
  }

  /// 更新模块状态
  Future<void> _updateModuleState(ModuleMetadata metadata, Directory moduleDir) async {
    metadata.localPath = moduleDir.path;
    metadata.lastUpdated = DateTime.now();
    // 将状态写入 ModuleStateService（持久化模块元数据）
    try {
      final moduleState = ModuleStateService();
      await moduleState.initialize();
      await moduleState.updateModuleState(
        metadata.id,
        localPath: moduleDir.path,
        isDownloaded: true,
      );
      // 同时保存完整元数据以便列表读取
      await moduleState.saveModuleMetadata(metadata);
    } catch (e) {
      // 捕获异常但不阻塞导入流程
    }
  }

  /// 获取模块的媒体文件
  Future<File?> getMediaFile(String moduleId, String filename) async {
    final moduleDir = Directory(p.join(_mediaDir!.path, moduleId));
    if (!await moduleDir.exists()) return null;

    final file = File(p.join(moduleDir.path, filename));
    if (!await file.exists()) return null;

    return file;
  }

  /// 删除模块内容
  Future<void> deleteModuleContent(String moduleId) async {
    // 1. 删除媒体文件
    final moduleDir = Directory(p.join(_mediaDir!.path, moduleId));
    if (await moduleDir.exists()) {
      await moduleDir.delete(recursive: true);
    }

    // 2. 删除向量数据
    await _storage.deleteModuleEmbeddings(moduleId);
  }

  /// 计算模块内容大小（字节）
  Future<int> getModuleSize(String moduleId) async {
    int size = 0;
    final moduleDir = Directory(p.join(_mediaDir!.path, moduleId));
    if (!await moduleDir.exists()) return 0;

    // 递归计算目录大小
    await for (final entity in moduleDir.list(recursive: true)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  /// 检查模块文件完整性
  Future<bool> verifyModuleContent(String moduleId) async {
    final moduleDir = Directory(p.join(_mediaDir!.path, moduleId));
    if (!await moduleDir.exists()) return false;
    // 简单完整性检查实现：
    // 1. 至少包含一个 embeddings JSON 文件或 embeddings 目录
    // 2. 媒体目录存在
    final files = moduleDir.listSync(recursive: true).whereType<File>().toList();
    final hasEmbeddingsFile = files.any((f) => f.path.endsWith('.json') && f.path.contains('embeddings'));
    final hasMedia = files.any((f) => !f.path.endsWith('.json'));

    return hasEmbeddingsFile || hasMedia;
  }
}
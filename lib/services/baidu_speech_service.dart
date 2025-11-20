import '../utils/logger.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// 百度语音服务（ASR + TTS）
class BaiduSpeechService {
  static final BaiduSpeechService _instance = BaiduSpeechService._internal();
  factory BaiduSpeechService() => _instance;
  BaiduSpeechService._internal();

  // ==================== 配置区 ====================
  
  // 百度语音API密钥
  String _apiKey = '2DRtvp1TwtUMJthF7oT7NwCa';
  String _secretKey = 'DXlAQPawliMeU2jyyo70WUiNPFBpJygf';
  
  // Token缓存
  String? _accessToken;
  DateTime? _tokenExpireTime;
  
  // 录音器
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordPath;
  
  // 播放器
  final AudioPlayer _player = AudioPlayer();
  bool _isTTSEnabled = true;
  
  // API端点
  static const String _tokenUrl = 'http://localhost:3000/api/baidu/speech/token';
  static const String _asrUrl = 'https://vop.baidu.com/server_api';

  // ==================== 初始化 ====================

  /// 配置API密钥
  void configure({required String apiKey, required String secretKey}) {
    _apiKey = apiKey;
    _secretKey = secretKey;
     Logger.info('百度语音服务配置完成');
  }

  /// 获取Access Token
  Future<String?> _getAccessToken() async {
    // 如果token有效，直接返回
    if (_accessToken != null && 
        _tokenExpireTime != null && 
        DateTime.now().isBefore(_tokenExpireTime!)) {
      return _accessToken;
    }

    try {
  Logger.info('获取百度语音Token...');
      
      // 使用后端代理获取Token
      final dio = Dio();
      final response = await dio.post(
        _tokenUrl,
        data: {
          'apiKey': _apiKey,
          'secretKey': _secretKey,
        },
      );

      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'];
        final expiresIn = response.data['expires_in'] as int;
        _tokenExpireTime = DateTime.now().add(Duration(seconds: expiresIn - 300));
        
  Logger.success('Token获取成功');
        return _accessToken;
      }
      
      return null;
    } catch (e) {
  Logger.error('Token获取失败: $e', error: e);
      return null;
    }
  }

  // ==================== ASR（语音识别）====================

  /// 开始录音
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    try {
      // 检查麦克风权限
      if (await _recorder.hasPermission()) {
        // 获取临时文件路径
        final tempDir = await getTemporaryDirectory();
        _recordPath = '${tempDir.path}/voice_input.wav';
        
        // 开始录音
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav, // 使用WAV格式
            sampleRate: 16000, // 百度要求16k采样率
            numChannels: 1, // 单声道
          ),
          path: _recordPath!,
        );
        
        _isRecording = true;
  Logger.info('开始录音...');
        return true;
      } else {
  Logger.error('麦克风权限未授予');
        return false;
      }
    } catch (e) {
  Logger.error('录音启动失败: $e', error: e);
      return false;
    }
  }

  /// 停止录音并识别
  Future<String?> stopRecordingAndRecognize() async {
    if (!_isRecording) return null;

    try {
      // 停止录音
      final path = await _recorder.stop();
      _isRecording = false;
  Logger.info('录音结束');

      if (path == null || _recordPath == null) {
  Logger.error('录音文件不存在');
        return null;
      }

      // 读取音频文件
      final audioFile = File(_recordPath!);
      final audioBytes = await audioFile.readAsBytes();
      
      // 调用百度ASR
      return await _recognizeSpeech(audioBytes);
      
    } catch (e, st) {
      Logger.error('停止录音失败: $e', error: e, stackTrace: st);
      _isRecording = false;
      return null;
    }
  }

  /// 调用百度语音识别API
  Future<String?> _recognizeSpeech(Uint8List audioData) async {
    try {
  Logger.info('调用百度语音识别...');
      
      final token = await _getAccessToken();
      if (token == null) return null;

      final dio = Dio();
      
      // 将音频数据转为Base64
      final audioBase64 = base64Encode(audioData);
      
      final response = await dio.post(
        _asrUrl,
        queryParameters: {
          'dev_pid': 1537, // 普通话(纯中文识别)
          'cuid': 'xiaapp',
          'token': token,
        },
        data: {
          'format': 'wav',
          'rate': 16000,
          'channel': 1,
          'speech': audioBase64,
          'len': audioData.length,
        },
        options: Options(
          contentType: 'application/json',
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final result = response.data;
        if (result['err_no'] == 0) {
          final text = result['result'][0] as String;
          Logger.success('识别结果: $text');
          return text;
        } else {
          Logger.error('识别失败: ${result['err_msg']}');
          return null;
        }
      }
      
      return null;
    } catch (e) {
  Logger.error('语音识别异常: $e', error: e);
      return null;
    }
  }

  // ==================== TTS（语音合成）====================

  /// 文字转语音并播放
  Future<void> speak(String text) async {
    if (!_isTTSEnabled || text.isEmpty) return;

    try {
  Logger.info('调用百度TTS: ${text.substring(0, text.length > 20 ? 20 : text.length)}...');
      
      final token = await _getAccessToken();
      if (token == null) return;

      // 构建请求URL
      final ttsParams = {
        'tex': text, // 合成文本
        'tok': token,
        'cuid': 'xiaapp',
        'ctp': '1',
        'lan': 'zh',
        
        'per': '5111', // ⭐ 度小鹿（温柔可爱、亲和力强）
        'spd': '5',   // 语速：5（适中，不急不缓）
        'pit': '6',   // 音调：6（略高，体现少年感）
        'vol': '10',  // 音量：10（清晰响亮）
        
        'aue': '6', // 音频格式：3-MP3、6-WAV
      };

      // 通过后端代理获取TTS音频
      final queryString = ttsParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final proxyUrl = 'http://localhost:3000/api/baidu/speech/tts?$queryString';
      
      // 播放音频
      await _player.stop(); // 停止之前的播放
      try {
        _player.setReleaseMode(ReleaseMode.stop);
        await _player.play(UrlSource(proxyUrl));
  Logger.success('开始播放语音');
      } catch (playError) {
  Logger.error('音频播放失败: $playError', error: playError);
        // 尝试通过dio先获取音频数据再播放
        try {
          final dio = Dio();
          final response = await dio.get<Uint8List>(
            proxyUrl,
            options: Options(
              responseType: ResponseType.bytes,
            ),
          );
          
          if (response.statusCode == 200 && response.data != null) {
            await _player.play(BytesSource(response.data!));
            Logger.success('通过字节数据播放语音成功');
          } else {
            Logger.error('获取音频数据失败，状态码: ${response.statusCode}');
          }
        } catch (bytesError) {
          Logger.error('字节数据播放也失败: $bytesError', error: bytesError);
        }
      }
      
    } catch (e) {
  Logger.error('TTS异常: $e', error: e);
    }
  }

  /// 停止播放
  Future<void> stopSpeaking() async {
    await _player.stop();
  Logger.info('停止播放');
  }

  // ==================== 控制方法 ====================

  /// 设置TTS开关
  void setTTSEnabled(bool enabled) {
    _isTTSEnabled = enabled;
    if (!enabled) {
      stopSpeaking();
    }
  Logger.info('TTS ${enabled ? "开启" : "关闭"}');
  }

  /// 获取录音状态
  bool get isRecording => _isRecording;

  /// 获取TTS状态
  bool get isTTSEnabled => _isTTSEnabled;

  /// 检查API是否已配置
  bool isConfigured() {
    return _apiKey != 'YOUR_API_KEY' && _secretKey != 'YOUR_SECRET_KEY';
  }

  /// 释放资源
  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}

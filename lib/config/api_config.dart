import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// API 配置管理类
/// - 使用 SharedPreferences 存储加密后的配置
/// - 提供统一的配置访问接口
/// - 支持运行时更新配置
class APIConfig {
  static const String _configKey = 'api_config';
  static const String _encryptedPrefix = 'enc:';
  
  // 单例模式
  static final APIConfig _instance = APIConfig._internal();
  factory APIConfig() => _instance;
  APIConfig._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // 默认配置（用于首次运行）
  static const Map<String, dynamic> _defaultBaiduAgent = {
    'appId': '',
    'bearerToken': '',
    'useProxy': true,
    'proxyBaseUrl': 'http://localhost:3000/api/baidu',
    'apiBaseUrl': 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat',
  };

  static const Map<String, dynamic> _defaultBaiduSpeech = {
    'apiKey': '2DRtvp1TwtUMJthF7oT7NwCa',  // 临时配置，将通过环境变量或安全存储替换
    'secretKey': 'DXlAQPawliMeU2jyyo70WUiNPFBpJygf',
    'tokenUrl': 'https://aip.baidubce.com/oauth/2.0/token',
    'asrUrl': 'https://vop.baidu.com/server_api',
    'ttsUrl': 'https://tsn.baidu.com/text2audio',
  };

  /// 初始化服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      
      // 首次运行时写入默认配置
      if (!_prefs.containsKey(_configKey)) {
        await _saveConfig({
          'baiduAgent': _defaultBaiduAgent,
          'baiduSpeech': _defaultBaiduSpeech,
        });
      }
      
      _isInitialized = true;
      Logger.info('API 配置已加载');
    } catch (e, st) {
      Logger.error('API 配置初始化失败', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// 获取百度 Agent 配置
  Future<Map<String, dynamic>> getBaiduAgentConfig() async {
    final config = await _loadConfig();
    return config['baiduAgent'] as Map<String, dynamic>;
  }

  /// 获取百度语音服务配置
  Future<Map<String, dynamic>> getBaiduSpeechConfig() async {
    final config = await _loadConfig();
    return config['baiduSpeech'] as Map<String, dynamic>;
  }

  /// 更新百度 Agent 配置
  Future<void> updateBaiduAgentConfig(Map<String, dynamic> newConfig) async {
    final config = await _loadConfig();
    config['baiduAgent'] = newConfig;
    await _saveConfig(config);
  }

  /// 更新百度语音服务配置
  Future<void> updateBaiduSpeechConfig(Map<String, dynamic> newConfig) async {
    final config = await _loadConfig();
    config['baiduSpeech'] = newConfig;
    await _saveConfig(config);
  }

  // 加载配置（从 SharedPreferences）
  Future<Map<String, dynamic>> _loadConfig() async {
    if (!_isInitialized) {
      throw StateError('APIConfig 未初始化');
    }

    final encrypted = _prefs.getString(_configKey);
    if (encrypted == null) {
      throw StateError('配置未找到');
    }

    if (encrypted.startsWith(_encryptedPrefix)) {
      final decoded = _decrypt(encrypted.substring(_encryptedPrefix.length));
      return json.decode(decoded) as Map<String, dynamic>;
    }

    // 向后兼容：未加密的配置
    return json.decode(encrypted) as Map<String, dynamic>;
  }

  // 保存配置（到 SharedPreferences）
  Future<void> _saveConfig(Map<String, dynamic> config) async {
    if (!_isInitialized) {
      throw StateError('APIConfig 未初始化');
    }

    final jsonStr = json.encode(config);
    final encrypted = _encryptedPrefix + _encrypt(jsonStr);
    await _prefs.setString(_configKey, encrypted);
  }

  // 简单的加密实现（TODO: 使用更安全的方式存储和管理密钥）
  String _encrypt(String text) {
    const key = 'your-secret-key';  // 临时密钥，应使用安全存储
    final bytes = utf8.encode(text);
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(bytes);
    return '${base64.encode(bytes)}.${base64.encode(digest.bytes)}';
  }

  // 解密并验证
  String _decrypt(String encrypted) {
    const key = 'your-secret-key';  // 临时密钥，应使用安全存储
    final parts = encrypted.split('.');
    if (parts.length != 2) {
      throw const FormatException('无效的加密格式');
    }

    final data = base64.decode(parts[0]);
    final hmac = base64.decode(parts[1]);
    
    // 验证 HMAC
    final computedHmac = Hmac(sha256, utf8.encode(key))
        .convert(data)
        .bytes;
    
    if (!listEquals(hmac, computedHmac)) {
      throw const SecurityException('配置完整性验证失败');
    }

    return utf8.decode(data);
  }
}

/// 比较两个 List<int>
bool listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);
  @override
  String toString() => 'SecurityException: $message';
}

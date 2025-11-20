import '../utils/logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'proxy_manager.dart';

/// 百度千帆AppBuilder Agent API 服务（智能代理）
class BaiduAPIService {
  static final BaiduAPIService _instance = BaiduAPIService._internal();
  factory BaiduAPIService() => _instance;
  BaiduAPIService._internal();

  // ========== 配置 ==========
  final String _appId = '19ad2919-ccf4-491c-9996-becd836e1555';
  final String _bearerToken = 'bce-v3/ALTAK-zJvRFvLCjZBpivWd5utpE/c3e56ae6add11120b01ac1dfa8de7c013dfac717';

  final ProxyManager _proxyManager = ProxyManager();
  final String _apiBaseUrl = 'https://qianfan.baidubce.com/v2/app';

  String? _conversationId;
  
  /// 是否使用代理（Web环境自动使用，移动端不使用）
  bool get _useProxy => kIsWeb && _proxyManager.isRunning;
  
  /// 获取代理URL（动态）
  String get _proxyBaseUrl => _proxyManager.baseUrl;

  void configure({required String appId, required String bearerToken}) {
    // 保留以便未来支持动态配置
  }

  bool isConfigured() => _appId.isNotEmpty && _bearerToken.isNotEmpty;

  void resetConversation() {
    _conversationId = null;
    Logger.info('会话已重置');
  }

  Future<String?> chat(String message, {String? contextPrompt}) async {
    try {
      if (_useProxy) {
        return await _chatViaProxy(message, contextPrompt: contextPrompt);
      }
      return await _chatDirect(message, contextPrompt: contextPrompt);
    } catch (e, st) {
      Logger.error('百度Agent异常', error: e, stackTrace: st);
      return null;
    }
  }

  // 直接调用（移动端）
  Future<String?> _chatDirect(String message, {String? contextPrompt}) async {
    if (_conversationId == null) {
      final created = await _createConversationDirect();
      if (created == null) {
        Logger.warning('无法创建会话，跳过百度API调用');
        return null;
      }
    }

    Logger.chat('调用百度Agent... 会话ID: $_conversationId 问题: $message');

    final url = Uri.parse('$_apiBaseUrl/conversation/runs');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_bearerToken',
        },
        body: jsonEncode({
          'app_id': _appId,
          'query': contextPrompt != null ? '$contextPrompt\n\n$message' : message,
          'conversation_id': _conversationId ?? '',
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final answer = data['answer'] ?? '';
        if (answer != null && answer.toString().isNotEmpty) {
          Logger.success('百度Agent回答成功，长度: ${answer.toString().length}');
          return answer.toString();
        }
        Logger.warning('API返回空答案');
        return null;
      }

      Logger.error('百度Agent调用失败: ${response.statusCode} \n响应: ${response.body}');
      if (response.statusCode == 401) {
        _conversationId = null; // token 可能过期
        Logger.warning('Token 可能过期，已重置会话ID');
      }
      return null;
    } catch (e, st) {
      Logger.error('直接调用失败', error: e, stackTrace: st);
      return null;
    }
  }

  Future<String?> _createConversationDirect() async {
    final url = Uri.parse('$_apiBaseUrl/conversation');
    try {
      Logger.info('创建新会话（直接调用）...');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_bearerToken',
        },
        body: jsonEncode({'app_id': _appId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final conversationId = data['conversation_id'] ?? '';
        if (conversationId != null && conversationId.toString().isNotEmpty) {
          _conversationId = conversationId.toString();
          Logger.success('会话创建成功: $_conversationId');
          return _conversationId;
        }
        Logger.warning('会话ID为空');
        return null;
      }
      Logger.error('会话创建失败: ${response.statusCode} \n响应: ${response.body}');
      return null;
    } catch (e, st) {
      Logger.error('会话创建异常', error: e, stackTrace: st);
      return null;
    }
  }

  // 通过代理（Web 环境）
  Future<String?> _chatViaProxy(String message, {String? contextPrompt}) async {
    if (_conversationId == null) {
      final created = await _createConversationViaProxy();
      if (created == null) {
        Logger.warning('无法通过代理创建会话');
        return null;
      }
    }

    Logger.chat('通过代理调用百度Agent... 会话ID: $_conversationId 问题: $message');

    final url = Uri.parse('$_proxyBaseUrl/api/baidu/chat');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'appId': _appId,
          'bearerToken': _bearerToken,
          'query': contextPrompt != null ? '$contextPrompt\n\n$message' : message,
          'conversationId': _conversationId ?? '',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final answer = data['answer'] ?? '';
        if (answer != null && answer.toString().isNotEmpty) {
          Logger.success('百度Agent（代理）回答成功，长度: ${answer.toString().length}');
          return answer.toString();
        }
        Logger.warning('代理返回空答案');
        return null;
      }

      Logger.error('代理调用失败: ${response.statusCode} \n响应: ${response.body}');
      return null;
    } catch (e, st) {
      Logger.error('代理调用异常', error: e, stackTrace: st);
      return null;
    }
  }

  Future<String?> _createConversationViaProxy() async {
    final url = Uri.parse('$_proxyBaseUrl/api/baidu/conversation');
    try {
      Logger.info('通过代理创建会话...');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'appId': _appId, 'bearerToken': _bearerToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final conversationId = data['conversation_id'] ?? '';
        if (conversationId != null && conversationId.toString().isNotEmpty) {
          _conversationId = conversationId.toString();
          Logger.success('会话创建成功（通过代理）: $_conversationId');
          return _conversationId;
        }
        Logger.warning('代理返回的会话ID为空');
        return null;
      }

      Logger.error('代理创建会话失败: ${response.statusCode} \n响应: ${response.body}');
      return null;
    } catch (e, st) {
      Logger.error('代理创建会话异常', error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> testProxy() async {
    if (!_useProxy) {
      Logger.info('当前未启用代理模式');
      return true;
    }

    try {
      final url = Uri.parse('$_proxyBaseUrl/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        Logger.success('代理服务器连接正常');
        return true;
      }
      Logger.warning('代理服务器响应异常: ${response.statusCode}');
      return false;
    } catch (e, st) {
      Logger.error('代理服务器连接失败', error: e, stackTrace: st);
      return false;
    }
  }
}

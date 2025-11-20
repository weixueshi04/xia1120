import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/answer_response.dart';
import '../models/knowledge.dart';
import '../utils/logger.dart';
import 'baidu_api.dart';
import 'local_rag.dart';

/// 统一的 RAG 服务：编排本地知识库 + 远程 Baidu API。
class RagService {
  final LocalRAGService _local = LocalRAGService();
  final BaiduAPIService _remote = BaiduAPIService();

  // 负面反馈的持久化键，以及在内存中的缓存（测试环境也可用）。
  static const String _negativeFeedbackPrefsKey = 'rag_negative_feedbacks';
  static final List<Map<String, dynamic>> _negativeFeedbackMemory = [];

  // 可配置的置信度阈值。
  final double highConfidenceThreshold; // 高置信度，直接返回本地答案
  final double mediumConfidenceThreshold; // 中等置信度，尝试增强
  final double lowConfidenceThreshold; // 低置信度，仅作参考

  RagService({
    this.highConfidenceThreshold = 0.8,
    this.mediumConfidenceThreshold = 0.5,
    this.lowConfidenceThreshold = 0.3,
  });

  /// 初始化服务：加载本地知识库，并检查远程配置。
  Future<void> initialize() async {
    await _local.initialize();

    if (!_remote.isConfigured()) {
      Logger.warning('Baidu API 未配置，将仅使用本地知识库。');
    } else {
      Logger.info('RagService 初始化完成：本地知识库 + Baidu API。');
    }
  }

  /// 主搜索入口：按照置信度分级编排本地和远程答案。
  ///
  /// 流程：
  /// 1. 先查询本地知识库。
  /// 2. 高置信度（>= high）：直接返回本地答案。
  /// 3. 中等置信度（[medium, high)）：尝试用本地答案作为上下文调用 Baidu 增强。
  /// 4. 低置信度（[low, medium)）：优先使用 Baidu，附带本地答案作为参考。
  /// 5. 本地无匹配或低于 low：完全依赖 Baidu。
  Future<AnswerResponse?> search(String query) async {
    try {
      Logger.debug('RagService.search 开始：$query');

      // 1. 本地知识库检索
      final localResult = await _local.search(query);

      // 2. 高置信度：直接返回本地答案
      if (localResult != null &&
          localResult.confidence >= highConfidenceThreshold) {
        Logger.info(
          '使用高置信度本地答案（${localResult.confidence.toStringAsFixed(2)}）',
        );
        return localResult;
      }

      // 3. 中等置信度：尝试混合增强
      if (localResult != null &&
          localResult.confidence >= mediumConfidenceThreshold) {
        Logger.info('中等置信度本地答案，尝试使用 Baidu 进行增强');

        if (_remote.isConfigured()) {
          final enhanced = await _chatWithContext(
            query,
            localContext: localResult.content,
          );

          if (enhanced != null && enhanced.isNotEmpty) {
            return AnswerResponse(
              content: enhanced,
              // 将本地置信度与一个较高基准混合
              confidence: (localResult.confidence + 0.8) / 2,
              source: 'hybrid',
              references: localResult.references,
              metadata: {
                'local_confidence': localResult.confidence,
                'enhanced_by': 'baidu',
                ...?localResult.metadata,
              },
            );
          }
        }

        Logger.info('增强失败或未配置 Baidu，返回本地答案');
        return localResult;
      }

      // 4. 低置信度：主要依赖 Baidu，本地答案作为参考
      if (localResult != null &&
          localResult.confidence >= lowConfidenceThreshold) {
        Logger.info('低置信度本地答案，优先尝试 Baidu');

        if (_remote.isConfigured()) {
          final baiduAnswer = await _remote.chat(query);
          if (baiduAnswer != null && baiduAnswer.isNotEmpty) {
            return AnswerResponse(
              content: baiduAnswer,
              confidence: 0.6,
              source: 'baidu',
              references: null,
              metadata: {
                'local_reference': localResult.content,
                'local_confidence': localResult.confidence,
              },
            );
          }
        }

        // 远程失败时，退回本地答案（虽然置信度较低）
        return localResult;
      }

      // 5. 本地无有效匹配或置信度过低：完全依赖 Baidu
      Logger.info('本地无有效匹配，尝试使用 Baidu');
      if (_remote.isConfigured()) {
        final baiduAnswer = await _remote.chat(query);
        if (baiduAnswer != null && baiduAnswer.isNotEmpty) {
          return AnswerResponse(
            content: baiduAnswer,
            confidence: 0.6,
            source: 'baidu',
            references: null,
          );
        }
      }

      Logger.warning('本地与远程检索均未获得答案');
      return null;
    } catch (e, stackTrace) {
      Logger.error('RagService.search 出错', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 带上下文的 Baidu API 调用：使用本地答案作为补充信息。
  Future<String?> _chatWithContext(
    String query, {
    required String localContext,
  }) async {
    try {
      final prompt = '''
参考以下本地知识库信息回答用户问题：

【本地知识】
$localContext

【用户问题】
$query

请基于本地知识，给出更完整、准确的回答；若本地信息不足，可以适当补充。
''';

      return await _remote.chat(prompt);
    } catch (e) {
      Logger.error('RagService._chatWithContext 出错', error: e);
      return null;
    }
  }

  /// 用户反馈处理：正向反馈写入本地知识库，负向反馈进入队列。
  Future<void> processFeedback({
    required String query,
    required String answer,
    required bool isHelpful,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (isHelpful) {
        Logger.info('收到正向反馈，准备写入本地知识库');

        // 简单从查询中提取关键字
        final keywords = query
            .split(' ')
            .where((w) => w.length > 1)
            .take(5)
            .toList();

        await _local.addToKnowledgeBase(
          query: query,
          answer: answer,
          metadata: {
            'keywords': keywords,
            'category': '用户反馈',
            'source': source ?? 'unknown',
            'timestamp': DateTime.now().toIso8601String(),
            ...?metadata,
          },
        );

        Logger.info('反馈问答已写入本地知识库');
      } else {
        Logger.warning('收到负向反馈，加入负面反馈队列：$query');

        await _saveNegativeFeedback(
          query: query,
          answer: answer,
          source: source,
          metadata: metadata,
        );
      }
    } catch (e, stackTrace) {
      Logger.error('RagService.processFeedback 出错', error: e, stackTrace: stackTrace);
    }
  }

  /// 保存负面反馈：同时写入内存和 SharedPreferences（若可用）。
  Future<void> _saveNegativeFeedback({
    required String query,
    required String answer,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    final recordMap = <String, dynamic>{
      'query': query,
      'answer': answer,
      'source': source,
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 内存缓存，保证在测试环境中也能读取到。
    _negativeFeedbackMemory.add(recordMap);

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing =
          prefs.getStringList(_negativeFeedbackPrefsKey) ?? <String>[];

      existing.add(jsonEncode(recordMap));

      // 限制队列大小，最多保留 100 条
      if (existing.length > 100) {
        existing.removeAt(0);
      }

      await prefs.setStringList(_negativeFeedbackPrefsKey, existing);
      Logger.info('负面反馈已保存（总数：${existing.length}）');
    } catch (e) {
      // 持久化失败不影响内存缓存
      Logger.error('保存负面反馈失败', error: e);
    }
  }

  /// 获取负面反馈列表（内存 + 持久化）。
  Future<List<Map<String, dynamic>>> getNegativeFeedbacks() async {
    final memoryCopy =
        List<Map<String, dynamic>>.from(_negativeFeedbackMemory);

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing =
          prefs.getStringList(_negativeFeedbackPrefsKey) ?? <String>[];

      final fromPrefs = existing.map((record) {
        try {
          return jsonDecode(record) as Map<String, dynamic>;
        } catch (_) {
          return <String, dynamic>{};
        }
      }).where((r) => r.isNotEmpty).toList();

      return [...memoryCopy, ...fromPrefs];
    } catch (e) {
      Logger.error('获取负面反馈失败', error: e);
      return memoryCopy;
    }
  }

  /// 清空负面反馈队列。
  Future<void> clearNegativeFeedbacks() async {
    _negativeFeedbackMemory.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_negativeFeedbackPrefsKey);
      Logger.info('负面反馈队列已清空');
    } catch (e) {
      Logger.error('清空负面反馈失败', error: e);
    }
  }

  /// 获取服务统计信息（供调试和监控使用）。
  Map<String, dynamic> getStats() {
    return {
      'local': _local.getStats(),
      'remote_configured': _remote.isConfigured(),
      'thresholds': {
        'high': highConfidenceThreshold,
        'medium': mediumConfidenceThreshold,
        'low': lowConfidenceThreshold,
      },
    };
  }

  /// 按分类获取知识条目（透传到本地服务）。
  List<Knowledge> getKnowledgeByCategory(String category) {
    return _local.getByCategory(category);
  }

  /// 获取所有知识分类。
  List<String> getAllCategories() {
    return _local.getAllCategories();
  }

  // ==================== 知识盲盒相关封装 ====================

  /// 随机获取指定 UI 分类的知识（知识盲盒）。
  Future<Knowledge?> getRandomKnowledgeByCategory(String uiCategory) {
    return _local.getRandomKnowledgeByCategory(uiCategory);
  }

  /// 获取盲盒分类统计信息。
  Map<String, dynamic> getCategoryStats() {
    return _local.getCategoryStats();
  }

  /// 获取指定分类的展示历史。
  List<int> getKnowledgeHistory(String uiCategory) {
    return _local.getKnowledgeHistory(uiCategory);
  }

  /// 重置某个分类的展示历史。
  void resetCategoryHistory(String uiCategory) {
    _local.resetCategoryHistory(uiCategory);
  }

  /// 获取所有可用的 UI 分类。
  List<String> getAllUICategories() {
    return _local.getAllUICategories();
  }
}


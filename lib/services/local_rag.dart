import 'dart:math';

import 'package:flutter/services.dart';

import '../models/answer_response.dart';
import '../models/knowledge.dart';
import '../utils/logger.dart';

/// 本地知识库服务
///
/// 职责：
/// - 从 `assets/data/knowledge.json` 加载知识；
/// - 提供基于规则的本地检索（精确匹配 + 关键词匹配）；
/// - 维护简单的反馈学习（新增知识）；
/// - 支持“知识盲盒”按 UI 分类随机抽取知识。
class LocalRAGService {
  static final LocalRAGService _instance = LocalRAGService._internal();
  factory LocalRAGService() => _instance;
  LocalRAGService._internal();

  KnowledgeBase? _knowledgeBase;
  bool _isInitialized = false;
  int _nextId = 1000;
  final Random _random = Random();

  // 同义词表：用于后续扩展（当前搜索逻辑主要依赖问题/关键词）

  // 停用词：在提取关键词时过滤掉这些高频但无实际含义的词
  final Set<String> _stopWords = {
    '的',
    '了',
    '呢',
    '吗',
    '啊',
    '吧',
    '就',
    '还',
    '很',
    '也',
    '和',
    '或',
    '以及',
    '什么',
    '怎么',
    '如何',
    '为什麽',
  };

  /// 初始化知识库：优先从 JSON 资产加载，失败时使用内置默认数据。
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/knowledge.json');
      _knowledgeBase = KnowledgeBase.fromJsonString(jsonString);
      _isInitialized = true;

      if (_knowledgeBase!.knowledge.isNotEmpty) {
        final maxId = _knowledgeBase!.knowledge
            .map((k) => k.id)
            .reduce((a, b) => a > b ? a : b);
        _nextId = max(maxId + 1, _nextId);
      }

      Logger.info(
        '知识库加载成功，条数: ${_knowledgeBase!.knowledge.length}',
      );
    } catch (e) {
      Logger.error('知识库加载失败，将使用内置默认数据', error: e);
      _knowledgeBase = _buildDefaultKnowledgeBase();
      _isInitialized = true;
    }
  }

  /// 统一的文本预处理：小写 + 去标点 + 合并空白。
  String _normalize(String input) {
    var text = input.toLowerCase().trim();

    const punctuation = <String>[
      '？',
      '?',
      '！',
      '!',
      '。',
      '.',
      '，',
      ',',
      '、',
      '；',
      ';',
      '：',
      ':',
      '“',
      '”',
      '"',
      '‘',
      '’',
      '\'',
      '（',
      '）',
      '(',
      ')',
      '【',
      '】',
      '《',
      '》',
      '<',
      '>',
    ];

    for (final p in punctuation) {
      text = text.replaceAll(p, ' ');
    }

    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text;
  }

  /// 主搜索入口：返回带置信度的本地答案。
  Future<AnswerResponse?> search(String query) async {
    if (!_isInitialized) await initialize();
    final kb = _knowledgeBase;
    if (kb == null || kb.knowledge.isEmpty) return null;

    final normalizedQuery = _normalize(query);

    // 1. 精确匹配主问题（使用预处理后文本）
    for (final item in kb.knowledge) {
      if (_normalize(item.question) == normalizedQuery) {
        return AnswerResponse(
          content: item.answer,
          confidence: 1.0,
          source: 'local',
          references: [item.question],
          metadata: {
            'match_type': 'exact',
            'knowledge_id': item.id,
            'category': item.category,
          },
        );
      }
    }

    // 2. 精确匹配同义问题（如果存在）
    for (final item in kb.knowledge) {
      final synonyms = item.synonymQuestions;
      if (synonyms == null) continue;
      for (final synonym in synonyms) {
        if (_normalize(synonym) == normalizedQuery) {
          return AnswerResponse(
            content: item.answer,
            confidence: 0.95,
            source: 'local',
            references: [item.question],
            metadata: {
              'match_type': 'synonym_exact',
              'knowledge_id': item.id,
              'category': item.category,
            },
          );
        }
      }
    }

    // 3. 关键词匹配：简单评分，选取得分最高的一条
    Knowledge? best;
    double bestScore = 0;

    final queryWords =
        normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();

    for (final item in kb.knowledge) {
      double score = 0;

      final normalizedQuestion = _normalize(item.question);
      if (normalizedQuestion.contains(normalizedQuery) ||
          normalizedQuery.contains(normalizedQuestion)) {
        score += 10;
      }

      for (final keyword in item.keywords) {
        final normKeyword = _normalize(keyword);
        if (normKeyword.length < 2) continue;
        if (queryWords.any(
          (w) => w.contains(normKeyword) || normKeyword.contains(w),
        )) {
          score += 4;
        }
      }

      if (score > 0 && normalizedQuery.length >= 3) {
        final normalizedAnswer = _normalize(item.answer);
        if (normalizedAnswer.contains(normalizedQuery)) {
          score += 1;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }

    if (best == null || bestScore <= 0) {
      // 视为本地无法回答，例如“今天天气怎么样？”
      return null;
    }

    // 将规则得分映射到 0.3 - 0.9 之间，避免过低置信度
    final confidence = (bestScore / 20.0).clamp(0.3, 0.9);

    return AnswerResponse(
      content: best.answer,
      confidence: confidence,
      source: 'local',
      references: [best.question],
      metadata: {
        'match_type': 'keyword',
        'score': bestScore,
        'knowledge_id': best.id,
        'category': best.category,
      },
    );
  }

  /// 将新的问答对加入本地知识库（用于正向反馈）。
  Future<void> addToKnowledgeBase({
    required String query,
    required String answer,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) await initialize();
    final kb = _knowledgeBase;
    if (kb == null) return;

    final id = _nextId++;
    final category = (metadata?['category'] as String?) ?? '用户反馈';
    final keywords = (metadata?['keywords'] as List<String>?) ??
        _extractKeywordsFromQuery(query);

    final newKnowledge = Knowledge(
      id: id,
      question: query,
      answer: answer,
      keywords: keywords,
      category: category,
      synonymQuestions: metadata?['synonyms'] as List<String>?,
    );

    kb.knowledge.add(newKnowledge);
    Logger.info('新知识已添加: $query (ID: $id)');
  }

  List<String> _extractKeywordsFromQuery(String query) {
    final words =
        _normalize(query).split(' ').where((w) => w.length > 1).toList();
    return words.where((w) => !_stopWords.contains(w)).toList();
  }

  /// 按内部分类获取知识列表。
  List<Knowledge> getByCategory(String category) {
    if (_knowledgeBase == null) return [];
    return _knowledgeBase!.knowledge
        .where((k) => k.category == category)
        .toList();
  }

  /// 获取所有内部分类名称。
  List<String> getAllCategories() {
    if (_knowledgeBase == null) return [];
    return _knowledgeBase!.getAllCategories();
  }

  /// 获取知识库统计信息。
  Map<String, dynamic> getStats() {
    if (_knowledgeBase == null) {
      return {
        'total': 0,
        'categories': <String, int>{},
        'initialized': _isInitialized,
      };
    }

    return {
      'total': _knowledgeBase!.knowledge.length,
      'categories': _knowledgeBase!.getCategoryStats(),
      'initialized': _isInitialized,
    };
  }

  // ==================== 知识盲盒功能 ====================

  /// UI 分类到内部分类的映射。
  final Map<String, List<String>> _categoryMapping = {
    '非遗': ['非遗文化'],
    '农业': ['农业知识'],
    '学习': ['教育辅导'],
    // 故事类可以来自苗族故事 / 地理文化 / 历史人物
    '故事': ['苗族故事', '地理文化', '历史人物'],
  };

  /// 历史记录：每个 UI 分类最近展示过的知识 ID（最多保留 10 条）。
  final Map<String, List<int>> _categoryHistory = {
    '非遗': <int>[],
    '农业': <int>[],
    '学习': <int>[],
    '故事': <int>[],
  };

  /// 使用统计：每个 UI 分类的使用次数和最后一次使用时间。
  final Map<String, Map<String, dynamic>> _usageStats = {
    '非遗': {'count': 0, 'lastUsed': null},
    '农业': {'count': 0, 'lastUsed': null},
    '学习': {'count': 0, 'lastUsed': null},
    '故事': {'count': 0, 'lastUsed': null},
  };

  /// 按 UI 分类随机抽取一条知识（知识盲盒核心功能）。
  Future<Knowledge?> getRandomKnowledgeByCategory(String uiCategory) async {
    if (!_isInitialized) await initialize();
    if (_knowledgeBase == null || _knowledgeBase!.knowledge.isEmpty) {
      Logger.error('知识库未初始化或为空');
      return null;
    }

    final dbCategories = _categoryMapping[uiCategory];
    if (dbCategories == null) {
      Logger.error('未知的分类: $uiCategory');
      return null;
    }

    final categoryKnowledge = _knowledgeBase!.knowledge
        .where((k) => dbCategories.contains(k.category))
        .toList();

    if (categoryKnowledge.isEmpty) {
      Logger.warning('分类 $uiCategory 没有知识数据');
      return null;
    }

    final history = _categoryHistory[uiCategory] ?? <int>[];

    // 过滤掉最近展示过的知识（如果该分类条目数 > 1，则尽量避免重复）
    List<Knowledge> available = categoryKnowledge;
    if (history.isNotEmpty && categoryKnowledge.length > 1) {
      available = categoryKnowledge
          .where((k) => !history.contains(k.id))
          .toList();

      // 如果过滤后没有可用知识，说明都展示过了，重置历史
      if (available.isEmpty) {
        Logger.info('分类 $uiCategory 的知识已全部展示，重置历史记录');
        history.clear();
        available = categoryKnowledge;
      }
    }

    final chosen = available[_random.nextInt(available.length)];

    // 更新历史记录（最多保留 10 条）
    history.add(chosen.id);
    if (history.length > 10) {
      history.removeAt(0);
    }
    _categoryHistory[uiCategory] = history;

    // 更新使用统计
    final stats = _usageStats[uiCategory]!;
    stats['count'] = (stats['count'] as int) + 1;
    stats['lastUsed'] = DateTime.now();

    Logger.info(
      '知识盲盒: 分类=$uiCategory, 知识ID=${chosen.id}, 问题=${chosen.question}',
    );

    return chosen;
  }

  /// 获取盲盒分类统计信息。
  Map<String, dynamic> getCategoryStats() {
    if (_knowledgeBase == null) return {};

    final result = <String, dynamic>{};

    for (final entry in _categoryMapping.entries) {
      final uiCategory = entry.key;
      final dbCategories = entry.value;

      final count = _knowledgeBase!.knowledge
          .where((k) => dbCategories.contains(k.category))
          .length;

      result[uiCategory] = {
        'count': count,
        'usageCount': _usageStats[uiCategory]!['count'],
        'lastUsed': _usageStats[uiCategory]!['lastUsed']?.toString(),
        'historySize': _categoryHistory[uiCategory]?.length ?? 0,
      };
    }

    return result;
  }

  /// 获取指定 UI 分类的展示历史（返回一个新的列表以避免外部修改内部状态）。
  List<int> getKnowledgeHistory(String uiCategory) {
    return List<int>.from(_categoryHistory[uiCategory] ?? const <int>[]);
  }

  /// 重置指定 UI 分类的展示历史。
  void resetCategoryHistory(String uiCategory) {
    _categoryHistory[uiCategory] = <int>[];
    Logger.info('已重置分类 $uiCategory 的展示历史');
  }

  /// 获取所有可用的 UI 分类名称。
  List<String> getAllUICategories() {
    return _categoryMapping.keys.toList();
  }

  /// 默认知识库（降级方案）：当资产加载失败时提供的最小数据集。
  KnowledgeBase _buildDefaultKnowledgeBase() {
    return KnowledgeBase(knowledge: [
      Knowledge(
        id: 1,
        question: '你是谁？',
        answer:
            '我是夏同龢，清朝光绪年间的状元，来自贵州麻江。我很高兴能通过数字形式继续为家乡的教育事业服务！',
        keywords: ['夏同龢', '状元', '贵州', '麻江'],
        category: '历史人物',
        synonymQuestions: [
          '你叫什么名字？',
          '你的名字是什么？',
        ],
      ),
      Knowledge(
        id: 2,
        question: '什么是枫香蜡染？',
        answer:
            '枫香蜡染是苗族的传统非遗技艺，使用枫香树脂作为防染剂，在蓝靛染料中创造出精美的白色图案。',
        keywords: ['枫香', '蜡染', '非遗', '苗族'],
        category: '非遗文化',
      ),
      Knowledge(
        id: 3,
        question: '侗族大歌是什么？',
        answer:
            '侗族大歌是一种多声部无指挥、无伴奏的合唱形式，被列入人类非物质文化遗产代表作名录。',
        keywords: ['侗族大歌', '非遗', '合唱'],
        category: '非遗文化',
      ),
      Knowledge(
        id: 4,
        question: '麻小莓是什么？',
        answer: '麻小莓是南京农业大学帮助麻江打造的蓝莓品牌，带动了当地蓝莓产业发展。',
        keywords: ['麻小莓', '蓝莓', '南京农业大学'],
        category: '农业知识',
      ),
      Knowledge(
        id: 5,
        question: '怎样提高学习效率？',
        answer: '制定计划、合理休息、及时复习、善用错题本，都是提高学习效率的好方法。',
        keywords: ['学习', '效率', '复习'],
        category: '教育辅导',
      ),
      Knowledge(
        id: 6,
        question: '苗年节是什么时候？',
        answer: '苗年是苗族最重要的传统节日之一，多在农历十月举行，用来庆祝丰收和祈福。',
        keywords: ['苗年', '苗族', '节日'],
        category: '苗族故事',
      ),
      Knowledge(
        id: 7,
        question: '麻江在哪里？',
        answer: '麻江位于贵州省黔东南苗族侗族自治州，是一个以蓝莓产业和民族文化著称的县。',
        keywords: ['麻江', '地理', '贵州'],
        category: '地理文化',
      ),
    ]);
  }
}


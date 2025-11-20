import 'dart:convert';

/// 知识库条目模型（支持同义词）
class Knowledge {
  final int id;
  final String question;
  final String answer;
  final List<String> keywords;
  final String category;
  final List<String>? synonymQuestions; // 同义问题列表

  Knowledge({
    required this.id,
    required this.question,
    required this.answer,
    required this.keywords,
    required this.category,
    this.synonymQuestions,
  });

  factory Knowledge.fromJson(Map<String, dynamic> json) {
    return Knowledge(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
      keywords: (json['keywords'] as List).map((e) => e.toString()).toList(),
      category: json['category'] as String,
      synonymQuestions: json['synonym_questions'] != null
          ? (json['synonym_questions'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'keywords': keywords,
      'category': category,
      if (synonymQuestions != null) 'synonym_questions': synonymQuestions,
    };
  }

  /// 优化后的相似度算法（支持同义问题）
  double similarity(String query) {
    final queryLower = query.toLowerCase().trim();
    double score = 0;

    // 1. 完全匹配主问题（最高优先级）
    if (question.toLowerCase() == queryLower) {
      return 100.0;
    }

    // 2. 完全匹配同义问题
    if (synonymQuestions != null) {
      for (var synonym in synonymQuestions!) {
        if (synonym.toLowerCase() == queryLower) {
          return 95.0; // 略低于主问题，但足够高
        }
      }
    }

    // 3. 主问题包含查询
    if (question.toLowerCase().contains(queryLower)) {
      score += 10.0;
    }

    // 4. 同义问题包含查询
    if (synonymQuestions != null) {
      for (var synonym in synonymQuestions!) {
        if (synonym.toLowerCase().contains(queryLower)) {
          score += 8.0;
          break; // 只加一次分
        }
      }
    }

    // 5. 查询包含主问题
    if (queryLower.contains(question.toLowerCase())) {
      score += 8.0;
    }

    // 6. 关键词匹配（需要多个关键词才得分）
    int keywordMatchCount = 0;
    for (var keyword in keywords) {
      // 只匹配长度>=2的关键词（避免单字误匹配）
      if (keyword.length >= 2 && queryLower.contains(keyword.toLowerCase())) {
        keywordMatchCount++;
        score += 3.0;
      }
    }

    // 如果只匹配到1个关键词，且该关键词是单字，降低得分
    if (keywordMatchCount == 1 && 
        keywords.any((k) => k.length == 1 && queryLower.contains(k.toLowerCase()))) {
      score *= 0.5;
    }

    // 7. 答案包含查询（低优先级）
    if (answer.toLowerCase().contains(queryLower) && queryLower.length >= 3) {
      score += 1.0;
    }

    // 8. 分类权重
    if (queryLower.contains(category.toLowerCase()) || 
        category.toLowerCase().contains(queryLower)) {
      score += 2.0;
    }

    return score;
  }

  /// 将规则得分映射到 0.0 - 1.0 区间，便于作为置信度使用
  static double mapScoreToConfidence(double score) {
    if (score <= 0) return 0.0;
    // 规则得分的设计上，完全匹配返回 100，常规匹配通常小于 100
    // 使用线性映射并裁剪到 [0,1]
    final c = score / 100.0;
    if (c > 1.0) return 1.0;
    return c;
  }
}

/// 知识库数据集合
class KnowledgeBase {
  final List<Knowledge> knowledge;

  KnowledgeBase({required this.knowledge});

  factory KnowledgeBase.fromJson(Map<String, dynamic> json) {
    return KnowledgeBase(
      knowledge: (json['knowledge'] as List)
          .map((item) => Knowledge.fromJson(item))
          .toList(),
    );
  }

  /// 从JSON字符串加载
  factory KnowledgeBase.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return KnowledgeBase.fromJson(json);
  }

  /// 按分类获取知识
  List<Knowledge> getByCategory(String category) {
    return knowledge.where((k) => k.category == category).toList();
  }

  /// 获取所有分类
  List<String> getAllCategories() {
    return knowledge.map((k) => k.category).toSet().toList();
  }

  /// 统计信息
  Map<String, int> getCategoryStats() {
    final Map<String, int> stats = {};
    for (var k in knowledge) {
      stats[k.category] = (stats[k.category] ?? 0) + 1;
    }
    return stats;
  }
}

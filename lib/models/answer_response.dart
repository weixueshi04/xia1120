/// 答案响应模型
/// 
/// 包含答案内容、置信度、来源等信息
class AnswerResponse {
  final String content;
  final double confidence; // 0.0 - 1.0
  final String source; // 'local', 'hybrid', 'baidu'
  final List<String>? references;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // 额外元数据

  AnswerResponse({
    required this.content,
    required this.confidence,
    required this.source,
    this.references,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 是否需要验证(中低置信度)
  bool get needsVerification => confidence < 0.8;

  /// 是否高置信度
  bool get isHighConfidence => confidence >= 0.8;

  /// 是否中等置信度
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.8;

  /// 是否低置信度
  bool get isLowConfidence => confidence >= 0.3 && confidence < 0.5;

  /// 复制并修改
  AnswerResponse copyWith({
    String? content,
    double? confidence,
    String? source,
    List<String>? references,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return AnswerResponse(
      content: content ?? this.content,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      references: references ?? this.references,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'AnswerResponse(source: $source, confidence: ${confidence.toStringAsFixed(2)}, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }
}

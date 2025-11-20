 
class SearchResult {
  final String content;
  final double confidence;
  final String source;
  final List<String>? references;
  final Map<String, dynamic>? metadata;
  final bool needsVerification;

  SearchResult({
    required this.content,
    required this.confidence,
    required this.source,
    this.references,
    this.metadata,
    this.needsVerification = false,
  });

  SearchResult copyWith({
    String? content,
    double? confidence,
    String? source,
    List<String>? references,
    Map<String, dynamic>? metadata,
    bool? needsVerification,
  }) {
    return SearchResult(
      content: content ?? this.content,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      references: references ?? this.references,
      metadata: metadata ?? this.metadata,
      needsVerification: needsVerification ?? this.needsVerification,
    );
  }
}
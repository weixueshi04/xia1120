import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'embedding.g.dart';

@JsonSerializable()
class Embedding {
  final String id;         // 向量ID
  final String text;       // 原始文本
  final List<double> vec;  // 向量值
  final String moduleId;   // 所属模块ID
  final String type;       // 类型：text/image/audio
  final Map<String, dynamic>? metadata; // 元数据（如来源、时间等）
  
  Embedding({
    required this.id,
    required this.text,
    required this.vec,
    required this.moduleId,
    required this.type,
    this.metadata,
  });

  factory Embedding.fromJson(Map<String, dynamic> json) => _$EmbeddingFromJson(json);
  Map<String, dynamic> toJson() => _$EmbeddingToJson(this);

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'text': text,
      'vec': vec.join(','),  // 将向量转为逗号分隔的字符串
      'module_id': moduleId,
      'type': type,
      'metadata': metadata == null ? null : _jsonEncode(metadata!),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Embedding fromSqlite(Map<String, dynamic> row) {
    return Embedding(
      id: row['id'] as String,
      text: row['text'] as String,
      vec: (row['vec'] as String).split(',').map((s) => double.parse(s)).toList(),
      moduleId: row['module_id'] as String,
      type: row['type'] as String,
      metadata: row['metadata'] == null ? null : _jsonDecode(row['metadata'] as String),
    );
  }
  
  // 辅助方法：安全的JSON编解码
  static String _jsonEncode(Map<String, dynamic> data) {
    try {
      return Uri.encodeComponent(const JsonEncoder().convert(data));
    } catch (e) {
      return '{}';
    }
  }
  
  static Map<String, dynamic> _jsonDecode(String text) {
    try {
      return const JsonDecoder().convert(Uri.decodeComponent(text)) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}
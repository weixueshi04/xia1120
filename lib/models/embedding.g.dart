// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'embedding.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Embedding _$EmbeddingFromJson(Map<String, dynamic> json) => Embedding(
      id: json['id'] as String,
      text: json['text'] as String,
      vec: (json['vec'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      moduleId: json['moduleId'] as String,
      type: json['type'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$EmbeddingToJson(Embedding instance) => <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'vec': instance.vec,
      'moduleId': instance.moduleId,
      'type': instance.type,
      'metadata': instance.metadata,
    };

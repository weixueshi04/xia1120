// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModuleMetadata _$ModuleMetadataFromJson(Map<String, dynamic> json) =>
    ModuleMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      size: (json['size'] as num).toInt(),
      checksum: json['checksum'] as String,
      languages:
          (json['languages'] as List<dynamic>).map((e) => e as String).toList(),
      priority: (json['priority'] as num).toDouble(),
      dependencies: (json['dependencies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      downloadUrl: json['downloadUrl'] as String,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? false,
      localPath: json['localPath'] as String?,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$ModuleMetadataToJson(ModuleMetadata instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': instance.version,
      'size': instance.size,
      'checksum': instance.checksum,
      'languages': instance.languages,
      'priority': instance.priority,
      'dependencies': instance.dependencies,
      'downloadUrl': instance.downloadUrl,
      'isDownloaded': instance.isDownloaded,
      'isEnabled': instance.isEnabled,
      'localPath': instance.localPath,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };

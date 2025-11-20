import 'package:json_annotation/json_annotation.dart';

part 'module_metadata.g.dart';

@JsonSerializable()
class ModuleMetadata {
  final String id;
  final String name;
  final String version;
  final int size;
  final String checksum;
  final List<String> languages;
  final double priority;
  final List<String>? dependencies;
  final String downloadUrl;
  
  // 本地状态
  bool isDownloaded;
  bool isEnabled;
  String? localPath;
  DateTime? lastUpdated;

  ModuleMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.size,
    required this.checksum,
    required this.languages,
    required this.priority,
    this.dependencies,
    required this.downloadUrl,
    this.isDownloaded = false,
    this.isEnabled = false,
    this.localPath,
    this.lastUpdated,
  });

  factory ModuleMetadata.fromJson(Map<String, dynamic> json) =>
      _$ModuleMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleMetadataToJson(this);

  // 生成本地存储的键
  static String storageKey(String moduleId) => 'module_metadata_$moduleId';
}
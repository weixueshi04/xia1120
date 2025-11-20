class KnowledgeManifest {
  final String version;
  final DateTime lastUpdated;
  final List<KnowledgeModule> modules;
  final List<Category> categories;

  KnowledgeManifest({
    required this.version,
    required this.lastUpdated,
    required this.modules,
    required this.categories,
  });

  factory KnowledgeManifest.fromJson(Map<String, dynamic> json) {
    return KnowledgeManifest(
      version: json['version'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      modules: (json['modules'] as List)
          .map((e) => KnowledgeModule.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'lastUpdated': lastUpdated.toIso8601String(),
        'modules': modules.map((e) => e.toJson()).toList(),
        'categories': categories.map((e) => e.toJson()).toList(),
      };
}

class KnowledgeModule {
  final String id;
  final Map<String, String> name;
  final String version;
  final int size;
  final String checksum;
  final List<String> languages;
  final int priority;
  final String category;
  final List<String> tags;
  final List<String> dependencies;
  final String downloadUrl;
  final ModuleMetadata metadata;
  final String contentType;
  final String format;
  final String compressionType;

  KnowledgeModule({
    required this.id,
    required this.name,
    required this.version,
    required this.size,
    required this.checksum,
    required this.languages,
    required this.priority,
    required this.category,
    required this.tags,
    required this.dependencies,
    required this.downloadUrl,
    required this.metadata,
    required this.contentType,
    required this.format,
    required this.compressionType,
  });

  factory KnowledgeModule.fromJson(Map<String, dynamic> json) {
    return KnowledgeModule(
      id: json['id'] as String,
      name: Map<String, String>.from(json['name'] as Map),
      version: json['version'] as String,
      size: json['size'] as int,
      checksum: json['checksum'] as String,
      languages: (json['languages'] as List).cast<String>(),
      priority: json['priority'] as int,
      category: json['category'] as String,
      tags: (json['tags'] as List).cast<String>(),
      dependencies: (json['dependencies'] as List).cast<String>(),
      downloadUrl: json['downloadUrl'] as String,
      metadata: ModuleMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      contentType: json['contentType'] as String,
      format: json['format'] as String,
      compressionType: json['compressionType'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'size': size,
        'checksum': checksum,
        'languages': languages,
        'priority': priority,
        'category': category,
        'tags': tags,
        'dependencies': dependencies,
        'downloadUrl': downloadUrl,
        'metadata': metadata.toJson(),
        'contentType': contentType,
        'format': format,
        'compressionType': compressionType,
      };
}

class ModuleMetadata {
  final String author;
  final DateTime lastUpdated;
  final String description;
  final String license;

  ModuleMetadata({
    required this.author,
    required this.lastUpdated,
    required this.description,
    required this.license,
  });

  factory ModuleMetadata.fromJson(Map<String, dynamic> json) {
    return ModuleMetadata(
      author: json['author'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      description: json['description'] as String,
      license: json['license'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'author': author,
        'lastUpdated': lastUpdated.toIso8601String(),
        'description': description,
        'license': license,
      };
}

class Category {
  final String id;
  final Map<String, String> name;

  Category({
    required this.id,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: Map<String, String>.from(json['name'] as Map),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
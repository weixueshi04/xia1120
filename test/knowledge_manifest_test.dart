import 'package:flutter_test/flutter_test.dart';
import 'package:xiaapp/models/knowledge_manifest.dart';

void main() {
  group('KnowledgeManifest Model Tests', () {
    test('should parse JSON correctly', () {
      final json = {
        "version": "1.0.0",
        "lastUpdated": "2025-11-10T00:00:00Z",
        "modules": [
          {
            "id": "test_module",
            "name": {
              "zh": "测试模块",
              "en": "Test Module"
            },
            "version": "1.0.0",
            "size": 1024,
            "checksum": "test-checksum",
            "languages": ["zh-CN", "en-US"],
            "priority": 1,
            "category": "test",
            "tags": ["测试"],
            "dependencies": [],
            "downloadUrl": "https://test.com/module",
            "metadata": {
              "author": "Test Author",
              "lastUpdated": "2025-11-10T00:00:00Z",
              "description": "Test Description",
              "license": "Test License"
            },
            "contentType": "text",
            "format": "json",
            "compressionType": "none"
          }
        ],
        "categories": [
          {
            "id": "test",
            "name": {
              "zh": "测试类别",
              "en": "Test Category"
            }
          }
        ]
      };

      final manifest = KnowledgeManifest.fromJson(json);

      expect(manifest.version, equals("1.0.0"));
      expect(manifest.modules.length, equals(1));
      expect(manifest.categories.length, equals(1));

      final module = manifest.modules.first;
      expect(module.id, equals("test_module"));
      expect(module.name["zh"], equals("测试模块"));
      expect(module.name["en"], equals("Test Module"));
      expect(module.size, equals(1024));
      expect(module.priority, equals(1));
      expect(module.languages, contains("zh-CN"));
      expect(module.tags, contains("测试"));

      final category = manifest.categories.first;
      expect(category.id, equals("test"));
      expect(category.name["zh"], equals("测试类别"));
      expect(category.name["en"], equals("Test Category"));

      // 测试序列化回 JSON
      final encodedJson = manifest.toJson();
      expect(encodedJson["version"], equals("1.0.0"));
      expect(encodedJson["modules"].length, equals(1));
      expect(encodedJson["categories"].length, equals(1));
    });

    test('should handle empty lists', () {
      final json = {
        "version": "1.0.0",
        "lastUpdated": "2025-11-10T00:00:00Z",
        "modules": [],
        "categories": []
      };

      final manifest = KnowledgeManifest.fromJson(json);
      expect(manifest.modules, isEmpty);
      expect(manifest.categories, isEmpty);
    });
  });
}
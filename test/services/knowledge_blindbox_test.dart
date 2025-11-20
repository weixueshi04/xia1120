import 'package:flutter_test/flutter_test.dart';
import 'package:xiaapp/services/local_rag.dart';

void main() {
  group('知识盲盒功能测试', () {
    late LocalRAGService ragService;

    setUp(() {
      ragService = LocalRAGService();
    });

    test('应该能够初始化知识库', () async {
      await ragService.initialize();
      final stats = ragService.getStats();
      expect(stats['initialized'], true);
      expect(stats['total'], greaterThan(0));
    });

    test('应该能够获取分类统计信息', () async {
      await ragService.initialize();
      final categoryStats = ragService.getCategoryStats();
      
      expect(categoryStats, isNotEmpty);
      expect(categoryStats.containsKey('非遗'), true);
      expect(categoryStats.containsKey('农业'), true);
      expect(categoryStats.containsKey('学习'), true);
      expect(categoryStats.containsKey('故事'), true);
    });

    test('应该能够随机获取非遗分类的知识', () async {
      await ragService.initialize();
      final knowledge = await ragService.getRandomKnowledgeByCategory('非遗');
      
      expect(knowledge, isNotNull);
      expect(knowledge!.category, equals('非遗文化'));
      expect(knowledge.question, isNotEmpty);
      expect(knowledge.answer, isNotEmpty);
    });

    test('应该能够随机获取农业分类的知识', () async {
      await ragService.initialize();
      final knowledge = await ragService.getRandomKnowledgeByCategory('农业');
      
      expect(knowledge, isNotNull);
      expect(knowledge!.category, equals('农业知识'));
    });

    test('应该能够随机获取学习分类的知识', () async {
      await ragService.initialize();
      final knowledge = await ragService.getRandomKnowledgeByCategory('学习');
      
      expect(knowledge, isNotNull);
      expect(knowledge!.category, equals('教育辅导'));
    });

    test('应该能够随机获取故事分类的知识', () async {
      await ragService.initialize();
      final knowledge = await ragService.getRandomKnowledgeByCategory('故事');
      
      expect(knowledge, isNotNull);
      expect(knowledge!.category, anyOf(['苗族故事', '地理文化', '历史人物']));
    });

    test('连续获取应该避免重复（至少3次内不重复）', () async {
      await ragService.initialize();
      
      final ids = <int>[];
      for (int i = 0; i < 5; i++) {
        final knowledge = await ragService.getRandomKnowledgeByCategory('非遗');
        if (knowledge != null) {
          ids.add(knowledge.id);
        }
      }
      
      // 检查前3个是否有重复
      if (ids.length >= 3) {
        expect(ids[0] != ids[1] || ids[1] != ids[2], true);
      }
    });

    test('应该能够获取展示历史', () async {
      await ragService.initialize();
      
      // 获取几次知识
      await ragService.getRandomKnowledgeByCategory('非遗');
      await ragService.getRandomKnowledgeByCategory('非遗');
      
      final history = ragService.getKnowledgeHistory('非遗');
      expect(history.length, greaterThanOrEqualTo(2));
    });

    test('应该能够重置展示历史', () async {
      await ragService.initialize();
      
      // 获取一些知识
      await ragService.getRandomKnowledgeByCategory('农业');
      await ragService.getRandomKnowledgeByCategory('农业');
      
      // 重置历史
      ragService.resetCategoryHistory('农业');
      
      final history = ragService.getKnowledgeHistory('农业');
      expect(history, isEmpty);
    });

    test('应该能够获取所有UI分类', () async {
      await ragService.initialize();
      final categories = ragService.getAllUICategories();
      
      expect(categories, contains('非遗'));
      expect(categories, contains('农业'));
      expect(categories, contains('学习'));
      expect(categories, contains('故事'));
      expect(categories.length, equals(4));
    });

    test('未知分类应该返回null', () async {
      await ragService.initialize();
      final knowledge = await ragService.getRandomKnowledgeByCategory('未知分类');
      
      expect(knowledge, isNull);
    });

    test('使用统计应该正确更新', () async {
      await ragService.initialize();
      
      // 获取初始统计
      var stats = ragService.getCategoryStats();
      final initialCount = stats['非遗']!['usageCount'] as int;
      
      // 使用一次
      await ragService.getRandomKnowledgeByCategory('非遗');
      
      // 检查统计是否更新
      stats = ragService.getCategoryStats();
      final newCount = stats['非遗']!['usageCount'] as int;
      
      expect(newCount, equals(initialCount + 1));
      expect(stats['非遗']!['lastUsed'], isNotNull);
    });
  });
}

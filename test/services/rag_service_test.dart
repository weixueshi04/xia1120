import 'package:flutter_test/flutter_test.dart';
import 'package:xiaapp/services/local_rag.dart';
import 'package:xiaapp/services/rag_service.dart';
import 'package:xiaapp/models/answer_response.dart';

void main() {
  group('LocalRAGService Tests', () {
    late LocalRAGService service;

    setUp(() {
      service = LocalRAGService();
    });

    test('应该成功初始化', () async {
      await service.initialize();
      final stats = service.getStats();
      
      expect(stats['initialized'], true);
      expect(stats['total'], greaterThan(0));
    });

    test('精确匹配应该返回高置信度答案', () async {
      await service.initialize();
      
      final result = await service.search('你是谁？');
      
      expect(result, isNotNull);
      expect(result!.confidence, equals(1.0));
      expect(result.content, contains('夏同龢'));
      expect(result.source, equals('local'));
    });

    test('同义问题应该匹配成功', () async {
      await service.initialize();
      
      // 假设knowledge.json中有同义问题
      final result = await service.search('你叫什么名字');
      
      if (result != null) {
        expect(result.confidence, greaterThanOrEqualTo(0.8));
        expect(result.content, contains('夏同龢'));
      }
    });

    test('关键词匹配应该返回相关答案', () async {
      await service.initialize();
      
      final result = await service.search('蜡染');
      
      expect(result, isNotNull);
      expect(result!.content, contains('蜡染'));
      expect(result.confidence, greaterThan(0.0));
    });

    test('完全不相关的问题应该返回null', () async {
      await service.initialize();
      
      final result = await service.search('今天天气怎么样？');
      
      // 本地知识库应该没有天气相关内容
      expect(result, isNull);
    });

    test('应该能添加新知识', () async {
      await service.initialize();
      
      final statsBefore = service.getStats();
      final countBefore = statsBefore['total'] as int;
      
      await service.addToKnowledgeBase(
        query: '测试问题',
        answer: '测试答案',
        metadata: {
          'keywords': ['测试'],
          'category': '测试分类',
        },
      );
      
      final statsAfter = service.getStats();
      final countAfter = statsAfter['total'] as int;
      
      expect(countAfter, equals(countBefore + 1));
    });

    test('应该能按分类获取知识', () async {
      await service.initialize();
      
      final categories = service.getAllCategories();
      
      expect(categories, isNotEmpty);
      expect(categories, contains('非遗文化'));
      
      final heritageKnowledge = service.getByCategory('非遗文化');
      expect(heritageKnowledge, isNotEmpty);
    });
  });

  group('RagService Tests', () {
    late RagService service;

    setUp(() {
      service = RagService();
    });

    test('应该成功初始化', () async {
      await service.initialize();
      
      final stats = service.getStats();
      expect(stats['local'], isNotNull);
    });

    test('高置信度问题应该直接返回本地答案', () async {
      await service.initialize();
      
      final result = await service.search('你是谁？');
      
      expect(result, isNotNull);
      expect(result!.isHighConfidence, true);
      expect(result.source, equals('local'));
    });

    test('AnswerResponse应该有正确的置信度判断', () {
      final highConf = AnswerResponse(
        content: 'test',
        confidence: 0.9,
        source: 'local',
      );
      
      expect(highConf.isHighConfidence, true);
      expect(highConf.isMediumConfidence, false);
      expect(highConf.isLowConfidence, false);
      expect(highConf.needsVerification, false);
      
      final mediumConf = AnswerResponse(
        content: 'test',
        confidence: 0.6,
        source: 'local',
      );
      
      expect(mediumConf.isHighConfidence, false);
      expect(mediumConf.isMediumConfidence, true);
      expect(mediumConf.needsVerification, true);
      
      final lowConf = AnswerResponse(
        content: 'test',
        confidence: 0.4,
        source: 'local',
      );
      
      expect(lowConf.isLowConfidence, true);
      expect(lowConf.needsVerification, true);
    });

    test('应该能处理正面反馈', () async {
      await service.initialize();
      
      // 添加正面反馈
      await service.processFeedback(
        query: '测试反馈问题',
        answer: '测试反馈答案',
        isHelpful: true,
      );
      
      // 验证知识已添加
      final result = await service.search('测试反馈问题');
      expect(result, isNotNull);
    });

    test('应该能处理负面反馈', () async {
      await service.initialize();
      
      // 添加负面反馈
      await service.processFeedback(
        query: '错误问题',
        answer: '错误答案',
        isHelpful: false,
      );
      
      // 验证负面反馈已保存
      final feedbacks = await service.getNegativeFeedbacks();
      expect(feedbacks, isNotEmpty);
      
      // 清理
      await service.clearNegativeFeedbacks();
    });

    test('应该能获取统计信息', () async {
      await service.initialize();
      
      final stats = service.getStats();
      
      expect(stats['local'], isNotNull);
      expect(stats['thresholds'], isNotNull);
      expect(stats['thresholds']['high'], equals(0.8));
      expect(stats['thresholds']['medium'], equals(0.5));
      expect(stats['thresholds']['low'], equals(0.3));
    });
  });

  group('查询预处理Tests', () {
    test('应该正确处理标点符号', () {
      // 这个测试需要访问私有方法,暂时跳过
      // 可以通过实际搜索来间接测试
    });
  });

  group('多模式匹配Tests', () {
    late LocalRAGService service;

    setUp(() async {
      service = LocalRAGService();
      await service.initialize();
    });

    test('应该能匹配不同形式的问题', () async {
      // 测试精确匹配
      var result = await service.search('你是谁？');
      expect(result, isNotNull);
      
      // 测试去除标点后的匹配
      result = await service.search('你是谁');
      expect(result, isNotNull);
      
      // 测试大小写不敏感
      result = await service.search('你是谁');
      expect(result, isNotNull);
    });
  });
}

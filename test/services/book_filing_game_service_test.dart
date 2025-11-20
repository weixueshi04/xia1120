import 'package:flutter_test/flutter_test.dart';
import 'package:xiaapp/services/book_filing_game_service.dart';

void main() {
  group('BookFilingGameService', () {
    final service = BookFilingGameService();

    test('should create demo task with fragments and categories', () {
      final task = service.createDemoTask();
      expect(task.id, isNotEmpty);
      expect(task.fragments, isNotEmpty);
      expect(task.categories, contains('四书'));
    });

    test('should validate fragment category correctly', () {
      final task = service.createDemoTask();
      final fragment = task.fragments.first;

      final correct = service.isCorrectCategory(fragment, fragment.category);
      final incorrect = service.isCorrectCategory(fragment, '诗经');

      expect(correct, isTrue);
      expect(incorrect, isFalse);
    });
  });
}


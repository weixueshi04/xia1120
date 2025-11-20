import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaapp/screens/game_book_filing_screen.dart';

void main() {
  testWidgets('GameBookFilingScreen builds and shows title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameBookFilingScreen(),
      ),
    );

    // AppBar title
    expect(find.text('古籍归档'), findsOneWidget);

    // Demo task title from service
    expect(find.textContaining('整理'), findsWidgets);
  });
}


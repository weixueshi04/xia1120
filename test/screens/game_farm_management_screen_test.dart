import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaapp/screens/game_farm_management_screen.dart';

void main() {
  testWidgets('GameFarmManagementScreen builds and shows dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameFarmManagementScreen(),
      ),
    );

    expect(find.text('麻江农场经营'), findsOneWidget);
    expect(find.text('资金'), findsWidgets);
    expect(find.text('天数'), findsWidgets);
  });
}


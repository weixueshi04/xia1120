// Basic Flutter widget test for XiaApp.
//
// Verifies that the app can start, show the Xia character,
// and render the main chat input and welcome message.

import 'package:flutter_test/flutter_test.dart';
import 'package:xiaapp/main.dart';
import 'package:flutter/material.dart' show TextField;

void main() {
  setUpAll(() {
    // Initialize test binding
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('app startup smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const XiaApp());

    // Verify that initial UI shows the Xia character name somewhere.
    expect(find.text('少年夏同龢'), findsWidgets);

    // Let animations settle and navigate to the main chat screen.
    await tester.pumpAndSettle();

    // Verify that the chat input is present.
    expect(find.byType(TextField), findsOneWidget);

    // Verify that the welcome message appears.
    expect(find.textContaining('你好！我是夏同龢'), findsOneWidget);
  });
}


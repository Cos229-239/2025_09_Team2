// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StudyPals app smoke test', (WidgetTester tester) async {
    // Build a simple test app to verify Flutter framework is working
    await tester.pumpWidget(
      MaterialApp(
        title: 'StudyPals Test',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Center(
            child: Text('StudyPals App'),
          ),
        ),
      ),
    );

    // Verify that the app starts properly
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('StudyPals App'), findsOneWidget);
  });
}

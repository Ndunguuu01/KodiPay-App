import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodipay/main.dart';

void main() {
  testWidgets('App smoke test - loads without crashing',
      (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    // Verify it renders something (not throwing).
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

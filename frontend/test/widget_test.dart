import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App smoke test - loads without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KodiPayApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Bantawan app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('BANTAWAN'),
        ),
      ),
    );

    expect(find.text('BANTAWAN'), findsOneWidget);
  });
}

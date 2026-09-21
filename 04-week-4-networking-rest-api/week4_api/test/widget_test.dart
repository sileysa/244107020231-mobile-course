import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Halaman Flutter dapat ditampilkan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Week 4 Networking REST API'),
          ),
        ),
      ),
    );

    expect(
      find.text('Week 4 Networking REST API'),
      findsOneWidget,
    );
  });
}
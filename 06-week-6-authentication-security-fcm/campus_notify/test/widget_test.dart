import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/pages/login_page.dart';

void main() {
  testWidgets(
    'LoginPage dapat ditampilkan',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
    },
  );
}

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cit_app/main.dart';

void main() {
  testWidgets('CIT App login test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CITApp());

    // Verify that login screen shows up.
    expect(find.text('ログイン'), findsOneWidget);
    expect(find.text('メールアドレス'), findsOneWidget);
  });
}

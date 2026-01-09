// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:alarm_app_1/data/alarm_provider.dart';
import 'package:alarm_app_1/screens/homescreen.dart';

void main() {
  testWidgets('Alarm app smoke test', (WidgetTester tester) async {
    // Build our app with provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AlarmProvider(),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify that our app bar title is present
    expect(find.text('My Alarm Clock'), findsOneWidget);

    // Verify empty state text
    expect(find.text('No alarms yet'), findsOneWidget);
  });
}

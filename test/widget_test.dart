// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthkit_integration_testing/main.dart';
import 'package:healthkit_integration_testing/services/health_service.dart';
import 'package:healthkit_integration_testing/services/notification_service.dart';
import 'package:mockito/mockito.dart';

class MockHealthService extends Mock implements HealthService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  testWidgets('App successfully builds', (WidgetTester tester) async {
    final mockHealthService = MockHealthService();
    final mockNotificationService = MockNotificationService();

    await tester.pumpWidget(MyApp(
      healthService: mockHealthService,
      notificationService: mockNotificationService,
    ));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

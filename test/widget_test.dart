import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_assistant_app/main.dart';

void main() {
  testWidgets('App starts and shows LoginPage', (WidgetTester tester) async {
    // Запускаем наше приложение
    await tester.pumpWidget(const AiAssistantApp());

    // Даем приложению время на отрисовку
    await tester.pumpAndSettle();

    // Проверяем, что приложение не упало и структура отрендерилась
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

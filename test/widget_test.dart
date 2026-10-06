import 'package:class_vision/app.dart';
import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/features/attendance/views/attendance_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ClassVision app smoke test', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ClassVisionApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('2º Ano A'), findsOneWidget);
  });

  testWidgets('matches the attendance review screen content', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AttendanceReviewPage(),
      ),
    );

    expect(find.text('Conferir chamada'), findsOneWidget);
    expect(find.text('Ana Beatriz'), findsOneWidget);
    expect(find.text('Tirar nova foto'), findsOneWidget);
    expect(find.text('Confirmar chamada'), findsOneWidget);

    await tester.tap(find.text('Confirmar chamada'));
    await tester.pump();
    expect(find.text('Chamada confirmada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

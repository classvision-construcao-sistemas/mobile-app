import 'package:class_vision/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('matches the attendance review screen content', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ClassVisionApp());

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

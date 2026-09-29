import 'package:class_vision/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('matches the AI processing screen content', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ClassVisionApp());

    expect(find.text('IA'), findsOneWidget);
    expect(find.text('Analisando a sala...'), findsOneWidget);
    expect(
      find.text('Comparando os rostos detectados com a lista da turma.'),
      findsOneWidget,
    );
    expect(find.text('Foto recebida'), findsOneWidget);
    expect(find.text('Rostos detectados'), findsOneWidget);
    expect(find.text('Identificando alunos'), findsOneWidget);
    expect(find.text('Preparando conferência'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Preparando conferência...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Análise concluída!'), findsOneWidget);
    expect(
      find.text('A conferência está pronta para ser revisada.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

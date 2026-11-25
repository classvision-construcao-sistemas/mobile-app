import 'dart:convert';

import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/models/auditoria_models.dart';
import 'package:class_vision/data/models/facial_recognition_models.dart';
import 'package:class_vision/features/attendance/widgets/class_photo_faces.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// PNG 4 × 3 (cinza), suficiente para o widget saber a proporção.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAQAAAADCAIAAAA7ljmRAAAAFUlEQVR4XmM8ceIEAwwwwVkMDKgcAFdUAl49wY72AAAAAElFTkSuQmCC',
);

void main() {
  test('reads face boxes from both services', () {
    final preview = AuditPreview.fromJson({
      'turmaId': 1,
      'alunos': <Object>[],
      'rostos': [
        {
          'x': .1,
          'y': .2,
          'largura': .05,
          'altura': .07,
          'alunoId': 20260001,
          'situacao': 'RECONHECIDO',
        },
        {
          'x': .5,
          'y': .5,
          'largura': .05,
          'altura': .07,
          'situacao': 'FORA_DA_TURMA',
        },
        {
          'x': .7,
          'y': .1,
          'largura': 0,
          'altura': .07,
          'situacao': 'NAO_IDENTIFICADO',
        },
      ],
    });
    expect(preview.faces, hasLength(2));
    expect(preview.faces.first.studentId, '20260001');
    expect(preview.faces.first.status, FaceStatus.recognized);
    expect(preview.faces.last.status, FaceStatus.outsideClass);

    final direct = RoomAuditResult.fromJson({
      'recognized_students': [
        {
          'student_id': '7',
          'confidence_score': .9,
          'relative_area': {'x': .1, 'y': .1, 'w': .2, 'h': .2},
        },
      ],
      'unrecognized_faces': [
        {
          'relative_area': {'x': .6, 'y': .1, 'w': .2, 'h': .2},
        },
      ],
      'unrecognized_count': 1,
      'total_faces_detected': 2,
    });
    expect(direct.faces.map((it) => it.status), [
      FaceStatus.recognized,
      FaceStatus.unidentified,
    ]);
    // Serviço antigo, sem caixa: nenhum rosto marcado, o resto igual.
    expect(
      RoomAuditResult.fromJson({
        'recognized_students': [
          {'student_id': '7', 'confidence_score': .9},
        ],
      }).faces,
      isEmpty,
    );
  });

  testWidgets('marks each face on the photo with the student name', (
    tester,
  ) async {
    final image = MemoryImage(_png);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: ClassPhotoFaces(
              imagePath: 'sala.jpg',
              image: image,
              faces: const [
                DetectedFace(
                  x: .1,
                  y: .3,
                  width: .2,
                  height: .3,
                  status: FaceStatus.recognized,
                  studentId: '20260001',
                ),
                DetectedFace(
                  x: .6,
                  y: .3,
                  width: .2,
                  height: .3,
                  status: FaceStatus.unidentified,
                ),
              ],
              nameFor: (id) => id == '20260001' ? 'Ana Clara Souza' : null,
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(image, tester.element(find.byType(ClassPhotoFaces))),
    );
    await tester.pump();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
    expect(find.text('1 da turma'), findsOneWidget);
    expect(find.text('Não identificado'), findsOneWidget);
    // Foto de 400 px de largura com proporção 4:3 → quadro a 40 px da borda
    // (o texto da etiqueta começa 6 px depois, pelo recuo interno).
    expect(tester.getTopLeft(find.text('Ana')).dx, closeTo(46, 1));
  });
}

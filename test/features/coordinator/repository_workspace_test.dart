import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/models/school_models.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:class_vision/features/classes/views/classes_page.dart';
import 'package:class_vision/features/history/views/history_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_turma_server.dart';

void main() {
  test('repository starts empty until the turma-service is loaded', () {
    expect(SchoolRepository().classes, isEmpty);
    expect(SchoolRepository().history, isEmpty);
  });

  testWidgets('classes page renders and opens repository-backed classes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = SchoolRepository()
      ..seedClasses([courseClass(nome: 'Turma criada agora', sala: 'Sala 9')]);
    String? openedId;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repository,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: ClassesPage(onOpenClass: (id) => openedId = id)),
        ),
      ),
    );

    expect(find.text('Turma criada agora'), findsOneWidget);
    await tester.tap(find.text('Turma criada agora'));
    expect(openedId, repository.classes.single.id);
  });

  testWidgets('attendance history reflects newly completed repository data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = SchoolRepository()
      ..seedClasses([courseClass(nome: 'Turma da sessão', sala: 'Sala 1')]);
    final classId = repository.classes.single.id;
    repository.addStudent(
      classId,
      const Student(
        id: 'a',
        name: 'Ana',
        registration: '1',
        guardian: '',
        phone: '',
        status: AttendanceStatus.present,
      ),
    );
    repository.completeAttendance(classId);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repository,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: HistoryPage()),
        ),
      ),
    );

    expect(find.textContaining('Turma da sessão'), findsOneWidget);
    expect(find.textContaining('1 de 1'), findsOneWidget);
  });
}

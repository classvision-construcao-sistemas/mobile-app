import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/models/school_models.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:class_vision/features/classes/views/classes_page.dart';
import 'package:class_vision/features/history/views/history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('demo repository is seeded without changing the empty default', () {
    expect(SchoolRepository().classes, isEmpty);
    expect(SchoolRepository().history, isEmpty);

    final demo = SchoolRepository.demo();
    expect(demo.profile.name, 'Lucas Ferreira');
    expect(demo.classes, isNotEmpty);
    expect(demo.history, isNotEmpty);
  });

  testWidgets('classes page renders and opens repository-backed classes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = SchoolRepository()
      ..addClass(name: 'Turma criada agora', room: 'Sala 9', time: '10:00');
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
      ..addClass(name: 'Turma da sessão', room: 'Sala 1', time: '08:00');
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

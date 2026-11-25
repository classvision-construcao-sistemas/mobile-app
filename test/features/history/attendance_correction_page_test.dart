import 'package:class_vision/core/theme/app_theme.dart';
import 'package:class_vision/data/models/school_models.dart';
import 'package:class_vision/data/repositories/auth_repository.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:class_vision/features/history/views/attendance_correction_page.dart';
import 'package:class_vision/features/history/views/history_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_auditoria_server.dart';
import '../../helpers/fake_auth_server.dart';
import '../../helpers/fake_turma_server.dart';

void main() {
  Future<(SchoolRepository, List<Map<String, dynamic>>)> confirmedAttendance({
    String role = 'COORDENADOR',
  }) async {
    final auth = AuthRepository(
      api: fakeAuthApi(claims: professorClaims(role: role)),
    );
    await auth.login(email: 'lucas@ifgoiano.edu.br', password: 'senha123');
    final saved = <Map<String, dynamic>>[];
    final repository = SchoolRepository(
      api: fakeTurmaApi(),
      auth: auth,
      auditoriaApi: fakeAuditoriaApi(saved: saved),
    );
    await repository.loadClasses();
    await repository.completeAttendance('1');
    return (repository, saved);
  }

  Future<void> pump(WidgetTester tester, SchoolRepository repository) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repository,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: HistoryPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('corrects a confirmed attendance from the history', (
    tester,
  ) async {
    final (repository, saved) = (await tester.runAsync(confirmedAttendance))!;
    await pump(tester, repository);

    await tester.tap(find.text('Corrigir'));
    await tester.pumpAndSettle();
    expect(find.byType(AttendanceCorrectionPage), findsOneWidget);

    await tester.tap(find.text('Salvar correção'));
    await tester.pumpAndSettle();
    expect(find.text('Altere a presença de algum aluno.'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(find.textContaining('(alterado)'), findsOneWidget);

    await tester.tap(find.text('Salvar correção'));
    await tester.pumpAndSettle();
    expect(find.text('Informe a justificativa da correção'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Justificativa'),
      'Aluno chegou depois da foto',
    );
    await tester.tap(find.text('Salvar correção'));
    await tester.pumpAndSettle();

    expect(find.byType(AttendanceCorrectionPage), findsNothing);
    expect(find.text('Corrigida'), findsOneWidget);
    expect(repository.history.single.status, AttendanceRecord.corrected);
    expect(
      (saved.single['correcoes'] as List).single['justificativa'],
      'Aluno chegou depois da foto',
    );
  });

  testWidgets('professors do not see the correction action', (tester) async {
    final (repository, _) = (await tester.runAsync(
      () => confirmedAttendance(role: 'PROFESSOR'),
    ))!;
    await pump(tester, repository);

    expect(find.text('Corrigir'), findsNothing);
  });
}

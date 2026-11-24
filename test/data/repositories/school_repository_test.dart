import 'package:class_vision/data/models/facial_recognition_models.dart';
import 'package:class_vision/data/models/school_models.dart';
import 'package:class_vision/data/models/turma_models.dart';
import 'package:class_vision/data/repositories/auth_repository.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:class_vision/data/services/turma_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../helpers/fake_auth_server.dart';
import '../../helpers/fake_turma_server.dart';

void main() {
  Future<AuthRepository> signedIn({String role = 'COORDENADOR'}) async {
    final auth = AuthRepository(
      api: fakeAuthApi(claims: professorClaims(role: role)),
    );
    await auth.login(email: 'lucas@ifgoiano.edu.br', password: 'senha123');
    return auth;
  }

  test('starts without seeded school data', () {
    final repository = SchoolRepository();

    expect(repository.classes, isEmpty);
    expect(repository.history, isEmpty);
    expect(repository.loaded, isFalse);
  });

  test('clears the session data on logout', () {
    final repository = SchoolRepository()..seedClasses([courseClass()]);
    repository.completeAttendance(repository.classes.single.id);

    repository.clear();

    expect(repository.classes, isEmpty);
    expect(repository.history, isEmpty);
    expect(repository.loaded, isFalse);
  });

  test('loads classes and courses from the turma-service', () async {
    final requests = <http.Request>[];
    final repository = SchoolRepository(
      api: fakeTurmaApi(requests: requests),
      auth: await signedIn(),
    );

    await repository.loadClasses();

    expect(repository.error, isNull);
    expect(repository.loaded, isTrue);
    expect(repository.classes.map((it) => it.name), [
      '2º Ano A',
      '1º Ano C',
      '2º Ano D',
    ]);
    final first = repository.classes.first;
    expect(first.id, '1');
    expect(first.room, 'Sala 204');
    expect(first.time, 'Matutino');
    expect(first.courseName, 'Técnico em Informática');
    expect(first.students.map((it) => it.registration), [
      '20260001',
      '20260002',
    ]);
    expect(first.students.first.enrollmentStatus, 'MATRICULADO');
    expect(
      requests.every(
        (request) => request.headers['Authorization']!.startsWith('Bearer '),
      ),
      isTrue,
    );
  });

  test('keeps attendance state when classes are reloaded', () async {
    final repository = SchoolRepository(
      api: fakeTurmaApi(),
      auth: await signedIn(),
    );
    await repository.loadClasses();
    repository.updateStudentStatus('1', '20260001', AttendanceStatus.absent);
    repository.completeAttendance('1');

    await repository.loadClasses();

    final classroom = repository.classById('1');
    expect(classroom.attendanceCompleted, isTrue);
    expect(classroom.students.first.status, AttendanceStatus.absent);
  });

  test('creates, updates and deletes classes', () async {
    final repository = SchoolRepository(
      api: fakeTurmaApi(classes: []),
      auth: await signedIn(),
    );
    await repository.loadClasses();

    final created = await repository.createClass(
      ClassPayload(
        year: 2027,
        name: 'ADS - 1º Período A',
        shift: ClassShift.noturno.apiName,
        room: 'Bloco B - Sala 12',
        startDate: DateTime(2027, 2, 8),
        courseId: 1,
      ),
    );
    expect(repository.classes.single.name, 'ADS - 1º Período A');
    expect(created.remote!.startDate, DateTime(2027, 2, 8));
    expect(created.time, 'Noturno');

    await repository.updateClass(
      created.id,
      const ClassPayload(
        year: 2027,
        name: 'ADS - 2º Período A',
        shift: 'MATUTINO',
        courseId: 1,
      ),
    );
    expect(repository.classes.single.name, 'ADS - 2º Período A');
    expect(repository.classes.single.time, 'Matutino');

    await repository.deleteClass(created.id);
    expect(repository.classes, isEmpty);
  });

  test('links students to remote classes by numeric registration', () async {
    final repository = SchoolRepository(
      api: fakeTurmaApi(),
      auth: await signedIn(role: 'SECRETARIO'),
    );
    await repository.loadClasses();
    const student = Student(
      id: '20269999',
      name: 'Ana Souza',
      registration: '20269999',
      guardian: 'Carla',
      phone: '',
    );

    await repository.enrollStudent('2', student);

    final enrolled = repository.classById('2').students.single;
    expect(enrolled.name, 'Ana Souza');
    expect(enrolled.enrollmentStatus, 'MATRICULADO');

    await expectLater(
      repository.enrollStudent('2', student),
      throwsA(
        isA<TurmaApiException>().having(
          (error) => error.message,
          'message',
          'Aluno já vinculado à turma',
        ),
      ),
    );

    await repository.unenrollStudent('2', enrolled);
    expect(repository.classById('2').students, isEmpty);
  });

  test('profiles without enrollment permission keep students local', () async {
    final requests = <http.Request>[];
    final repository = SchoolRepository(
      api: fakeTurmaApi(requests: requests),
      auth: await signedIn(role: 'PROFESSOR'),
    );
    await repository.loadClasses();
    requests.clear();

    await repository.enrollStudent(
      '2',
      const Student(
        id: 'abc',
        name: 'Aluno local',
        registration: 'abc',
        guardian: '',
        phone: '',
      ),
    );

    expect(requests, isEmpty);
    expect(repository.classById('2').students.single.name, 'Aluno local');
    expect(repository.canManageClasses, isFalse);
  });

  test('a 401 from the turma-service ends the session', () async {
    final auth = await signedIn();
    final repository = SchoolRepository(
      api: fakeTurmaApi(
        extra: (_) async =>
            jsonResponse({'status': 401, 'mensagem': 'Token inválido'}, 401),
      ),
      auth: auth,
    );

    await repository.loadClasses();

    expect(repository.error, 'Token inválido');
    expect(auth.isAuthenticated, isFalse);
    expect(auth.consumeLogoutReason(), contains('Entre novamente'));
  });

  test('maps registrations returned by Milvus to attendance statuses', () {
    final repository = SchoolRepository();
    final classId = repository.prepareAuditClass(null);
    const audit = RoomAuditResult(
      message: 'ok',
      recognizedStudents: [
        RecognizedStudent(
          studentId: 'student-1',
          confidenceScore: .92,
          facialArea: {},
        ),
        RecognizedStudent(
          studentId: 'student-2',
          confidenceScore: .63,
          facialArea: {},
        ),
      ],
      unrecognizedCount: 1,
      totalFacesDetected: 3,
    );

    repository.applyFacialRecognition(classId, audit);
    final students = repository.classById(classId).students;

    expect(students, hasLength(2));
    expect(students[0].status, AttendanceStatus.present);
    expect(students[0].confidence, .92);
    expect(students[1].status, AttendanceStatus.review);
    expect(students[1].confidence, .63);
  });
}

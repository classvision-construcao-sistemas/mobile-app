import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/facial_recognition_models.dart';
import '../models/school_models.dart';
import '../models/turma_models.dart';
import '../services/turma_api.dart';
import 'auth_repository.dart';

/// Turmas, cursos e estado das chamadas da sessão.
///
/// Cursos, turmas e vínculos de alunos vêm do `turma-service`, sempre com o
/// token da sessão de [auth]. A biometria continua exclusivamente no serviço
/// Milvus; nome, responsável e status de presença dos alunos ficam só em
/// memória durante a sessão, pois o turma-service guarda apenas o vínculo
/// (`alunoId` + situação). Nenhum dado fictício é pré-carregado.
///
/// Sem [api] ou [auth] (ex.: em testes) o repositório funciona só com o
/// estado local e as chamadas ao turma-service falham como sessão expirada.
class SchoolRepository extends ChangeNotifier {
  SchoolRepository({this.api, this.auth});

  final TurmaApi? api;
  final AuthRepository? auth;

  List<SchoolClass> _classes = [];
  List<Course> _courses = [];
  final List<AttendanceRecord> _history = [];

  /// Dados locais dos alunos cadastrados na sessão, por matrícula.
  final Map<String, Student> _knownStudents = {};

  bool _loading = false;
  bool _loaded = false;
  String? _error;
  int _generation = 0;
  bool _disposed = false;

  List<SchoolClass> get classes => List.unmodifiable(_classes);
  List<Course> get courses => List.unmodifiable(_courses);
  List<AttendanceRecord> get history => List.unmodifiable(_history);

  bool get loading => _loading;

  /// Se as turmas já foram carregadas ao menos uma vez nesta sessão.
  bool get loaded => _loaded;

  /// Mensagem do último erro ao carregar as turmas.
  String? get error => _error;

  bool get canManageClasses => auth?.role?.canManageClasses ?? false;
  bool get canManageEnrollments => auth?.role?.canManageEnrollments ?? false;

  Course? courseById(int? id) {
    if (id == null) return null;
    for (final course in _courses) {
      if (course.id == id) return course;
    }
    return null;
  }

  SchoolClass? findClassById(String? id) {
    if (id == null) return null;
    for (final classroom in _classes) {
      if (classroom.id == id) return classroom;
    }
    return null;
  }

  SchoolClass classById(String? id) {
    final classroom = findClassById(id);
    if (classroom == null) {
      throw StateError('Turma não encontrada.');
    }
    return classroom;
  }

  // ------------------------------------------------------------------ Carga

  /// Busca cursos e turmas no turma-service, preservando o estado local
  /// (presenças e alunos da sessão) das turmas já exibidas.
  Future<void> loadClasses() async {
    final generation = _generation;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      List<Course>? courses;
      try {
        courses = await _authorized((api, session) => api.listCourses(session));
      } on TurmaApiException catch (error) {
        if (error.isUnauthorized) rethrow;
        // Sem cursos as turmas continuam visíveis, só sem o nome do curso.
      }
      final remoteClasses = await _authorized(
        (api, session) => api.listClasses(session),
      );
      if (generation != _generation) return;
      if (courses != null) _courses = courses;
      final local = _classes.where((item) => !item.isRemote).toList();
      _classes = [for (final remote in remoteClasses) _merge(remote), ...local];
      _loaded = true;
    } on TurmaApiException catch (error) {
      if (generation != _generation) return;
      _error = error.message;
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Atualiza uma turma específica com os dados do serviço.
  Future<SchoolClass> refreshClass(String id) async {
    final remoteId = _requireRemoteId(id);
    final remote = await _authorized(
      (api, session) => api.getClass(session, remoteId),
    );
    return _replace(remote);
  }

  // ----------------------------------------------------------------- Cursos

  Future<Course> createCourse(CoursePayload payload) async {
    final course = await _authorized(
      (api, session) => api.createCourse(session, payload),
    );
    _courses = [..._courses, course];
    notifyListeners();
    return course;
  }

  // ----------------------------------------------------------------- Turmas

  Future<SchoolClass> createClass(ClassPayload payload) async {
    final remote = await _authorized(
      (api, session) => api.createClass(session, payload),
    );
    return _replace(remote);
  }

  Future<SchoolClass> updateClass(String id, ClassPayload payload) async {
    final remoteId = _requireRemoteId(id);
    final remote = await _authorized(
      (api, session) => api.updateClass(session, remoteId, payload),
    );
    return _replace(remote);
  }

  Future<void> deleteClass(String id) async {
    final remoteId = _requireRemoteId(id);
    await _authorized((api, session) => api.deleteClass(session, remoteId));
    _classes = _classes.where((item) => item.id != id).toList();
    notifyListeners();
  }

  // ------------------------------------------------------ Vínculo de alunos

  /// Adiciona o aluno à turma. Em turmas do turma-service, perfis com
  /// permissão também criam o vínculo na API (a matrícula é o `alunoId`).
  Future<void> enrollStudent(String classId, Student student) async {
    _knownStudents[student.registration] = student;
    final classroom = findClassById(classId);
    if (classroom == null) return;
    final remoteId = classroom.remoteId;
    if (remoteId == null || !canManageEnrollments) {
      addStudent(classId, student);
      return;
    }
    final studentId = int.tryParse(student.registration);
    if (studentId == null || studentId <= 0) {
      throw const TurmaApiException(
        'A matrícula precisa ser um número para vincular o aluno à turma.',
      );
    }
    final remote = await _authorized(
      (api, session) =>
          api.enrollStudent(session, remoteId, studentId: studentId),
    );
    _replace(remote);
  }

  /// Remove o aluno da turma (e o vínculo no turma-service, se existir).
  Future<void> unenrollStudent(String classId, Student student) async {
    final remoteId = findClassById(classId)?.remoteId;
    final studentId = int.tryParse(student.registration);
    if (remoteId != null &&
        studentId != null &&
        student.enrollmentStatus != null) {
      final remote = await _authorized((api, session) async {
        await api.unenrollStudent(session, remoteId, studentId);
        return api.getClass(session, remoteId);
      });
      _replace(remote);
      return;
    }
    _updateStudents(
      classId,
      (students) => students.where((it) => it.id != student.id).toList(),
    );
  }

  // ------------------------------------------------- Estado local da chamada

  /// Prepara um agrupamento de sessão para auditorias iniciadas sem turma.
  String prepareAuditClass(String? requestedId) {
    final selected = findClassById(requestedId);
    if (selected != null) return selected.id;

    const auditId = 'milvus-audit';
    if (findClassById(auditId) == null) {
      _classes = [
        ..._classes,
        const SchoolClass(
          id: auditId,
          name: 'Resultados do Milvus',
          room: 'Auditoria facial',
          time: '',
          students: [],
        ),
      ];
      notifyListeners();
    }
    return auditId;
  }

  /// Adiciona o aluno apenas na sessão atual (sem vínculo no turma-service).
  void addStudent(String classId, Student student) =>
      _updateStudents(classId, (students) => [...students, student]);

  void updateStudentStatus(
    String classId,
    String studentId,
    AttendanceStatus status,
  ) => _updateStudents(
    classId,
    (students) => students
        .map(
          (student) => student.id == studentId
              ? student.copyWith(status: status)
              : student,
        )
        .toList(),
  );

  void applyFacialRecognition(String classId, RoomAuditResult result) {
    final confidenceByRegistration = <String, double>{};
    for (final match in result.recognizedStudents) {
      final current = confidenceByRegistration[match.studentId] ?? 0;
      if (match.confidenceScore > current) {
        confidenceByRegistration[match.studentId] = match.confidenceScore;
      }
    }

    _classes = _classes.map((item) {
      if (item.id != classId) return item;

      final knownRegistrations = item.students
          .map((student) => student.registration)
          .toSet();
      final updated = item.students.map((student) {
        final confidence = confidenceByRegistration[student.registration];
        if (confidence == null) {
          return student.copyWith(
            status: AttendanceStatus.absent,
            confidence: 0,
          );
        }
        return student.copyWith(
          status: _statusForConfidence(confidence),
          confidence: confidence,
        );
      }).toList();

      // Quando a auditoria não possui uma turma local, exibe diretamente as
      // matrículas devolvidas pelo Milvus, sem inventar dados pessoais.
      for (final match in result.recognizedStudents) {
        if (knownRegistrations.add(match.studentId)) {
          updated.add(
            Student(
              id: match.studentId,
              name: match.studentId,
              registration: match.studentId,
              guardian: '',
              phone: '',
              status: _statusForConfidence(match.confidenceScore),
              confidence: match.confidenceScore,
            ),
          );
        }
      }

      return item.copyWith(students: updated);
    }).toList();
    notifyListeners();
  }

  void completeAttendance(String classId) {
    _classes = _classes
        .map(
          (item) => item.id == classId
              ? item.copyWith(attendanceCompleted: true)
              : item,
        )
        .toList();
    final classroom = findClassById(classId);
    if (classroom == null) return;
    _history.insert(
      0,
      AttendanceRecord(
        className: classroom.name,
        date: DateTime.now(),
        present: classroom.students
            .where((student) => student.status == AttendanceStatus.present)
            .length,
        absent: classroom.students
            .where((student) => student.status == AttendanceStatus.absent)
            .length,
      ),
    );
    notifyListeners();
  }

  /// Descarta os dados da sessão (chamado no logout).
  void clear() {
    _generation++;
    _classes = [];
    _courses = [];
    _history.clear();
    _knownStudents.clear();
    _loading = false;
    _loaded = false;
    _error = null;
    notifyListeners();
  }

  /// Substitui as turmas e cursos sem chamar a API (usado em testes).
  @visibleForTesting
  void seedClasses(
    List<CourseClass> classes, {
    List<Course> courses = const [],
  }) {
    _courses = [...courses];
    _classes = [for (final remote in classes) _merge(remote)];
    _loaded = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------- Interno

  static AttendanceStatus _statusForConfidence(double confidence) =>
      confidence >= .75 ? AttendanceStatus.present : AttendanceStatus.review;

  void _updateStudents(
    String classId,
    List<Student> Function(List<Student> students) update,
  ) {
    _classes = _classes
        .map(
          (item) => item.id == classId
              ? item.copyWith(students: update(item.students))
              : item,
        )
        .toList();
    notifyListeners();
  }

  int _requireRemoteId(String id) {
    final remoteId = findClassById(id)?.remoteId ?? int.tryParse(id);
    if (remoteId == null) {
      throw const TurmaApiException(
        'Esta turma existe só nesta sessão e não está no serviço de turmas.',
      );
    }
    return remoteId;
  }

  /// Converte a turma da API mantendo o estado local da versão anterior.
  SchoolClass _merge(CourseClass remote) {
    final previous = findClassById('${remote.id}');
    final previousStudents = {
      for (final student in previous?.students ?? const <Student>[])
        student.registration: student,
    };
    return SchoolClass.fromRemote(
      remote,
      course: courseById(remote.courseId),
      students: [
        for (final enrollment in remote.enrollments)
          _studentFor(enrollment, previousStudents['${enrollment.studentId}']),
      ],
      attendanceCompleted: previous?.attendanceCompleted ?? false,
    );
  }

  Student _studentFor(ClassEnrollment enrollment, Student? previous) {
    final registration = '${enrollment.studentId}';
    final base =
        previous ??
        _knownStudents[registration] ??
        Student(
          id: registration,
          name: 'Aluno $registration',
          registration: registration,
          guardian: '',
          phone: '',
        );
    return base.copyWith(enrollmentStatus: enrollment.status);
  }

  SchoolClass _replace(CourseClass remote) {
    final classroom = _merge(remote);
    final exists = findClassById(classroom.id) != null;
    _classes = exists
        ? [
            for (final item in _classes)
              item.id == classroom.id ? classroom : item,
          ]
        : [classroom, ..._classes];
    notifyListeners();
    return classroom;
  }

  /// Executa uma chamada com o token atual; `401` encerra a sessão.
  Future<T> _authorized<T>(
    Future<T> Function(TurmaApi api, AuthSession session) request,
  ) async {
    final api = this.api;
    final auth = this.auth;
    final session = auth?.session;
    if (api == null ||
        auth == null ||
        session == null ||
        !auth.ensureValidSession()) {
      throw const TurmaApiException(
        'Sua sessão expirou. Entre novamente.',
        statusCode: 401,
      );
    }
    try {
      return await request(api, session);
    } on TurmaApiException catch (error) {
      if (error.isUnauthorized && identical(auth.session, session)) {
        auth.logout(reason: 'Sua sessão foi encerrada. Entre novamente.');
      }
      rethrow;
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auditoria_models.dart';
import '../models/auth_models.dart';
import '../models/facial_recognition_models.dart';
import '../models/school_models.dart';
import '../models/turma_models.dart';
import '../services/auditoria_api.dart';
import '../services/facial_recognition_api.dart';
import '../services/turma_api.dart';
import 'auth_repository.dart';

/// Turmas, cursos, alunos e chamadas, integrando os microsserviços.
///
/// - Cursos, turmas e vínculos de alunos vêm do `turma-service`.
/// - Nome, responsável e telefone do aluno ficam com a biometria no
///   `reconhecimento-facial-service` ([facialApi]) e são buscados pela
///   matrícula, que é o `alunoId` do vínculo na turma.
/// - A chamada de turmas do turma-service é feita pelo `auditoria-service`
///   ([auditoriaApi]): prévia pela foto, confirmação e histórico.
///
/// Todas as chamadas usam o token da sessão de [auth]; um `401` encerra a
/// sessão. Sem [api] ou [auth] (ex.: em testes) o repositório funciona só com
/// o estado local. Nenhum dado fictício é pré-carregado.
class SchoolRepository extends ChangeNotifier {
  SchoolRepository({this.api, this.auth, this.auditoriaApi, this.facialApi});

  final TurmaApi? api;
  final AuthRepository? auth;
  final AuditoriaApi? auditoriaApi;
  final FacialRecognitionApi? facialApi;

  /// Matrículas já consultadas no serviço facial nesta sessão.
  final Set<String> _profileLookups = {};

  /// Última prévia do auditoria-service por turma (situação de cada face).
  final Map<String, AuditPreview> _previews = {};

  String? _historyError;

  /// Mensagem do último erro ao carregar o histórico de chamadas.
  String? get historyError => _historyError;

  /// Frequência do aluno nas chamadas registradas (nula sem chamadas).
  double? attendanceRateOf(String registration) {
    var total = 0;
    var present = 0;
    for (final record in _history) {
      final value = record.attendance[registration];
      if (value == null) continue;
      total++;
      if (value) present++;
    }
    return total == 0 ? null : present / total;
  }

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

  /// Se a chamada desta turma é registrada no auditoria-service: turma do
  /// turma-service e perfil autorizado (RN-01). Caso contrário a chamada usa
  /// o reconhecimento facial direto e fica só nesta sessão.
  bool recordsAuditFor(String? classId) =>
      auditoriaApi != null &&
      (auth?.role?.canRecordAttendance ?? false) &&
      (findClassById(classId)?.isRemote ?? false);

  /// Chamadas gravadas no auditoria-service podem ser corrigidas por quem
  /// registra chamadas (coordenador ou administrador).
  bool canCorrect(AttendanceRecord record) =>
      auditoriaApi != null &&
      record.isRemote &&
      (auth?.role?.canRecordAttendance ?? false);

  /// Nome do aluno de matrícula [registration] na turma [classId], se a
  /// turma estiver carregada.
  String? studentName(String? classId, String registration) {
    for (final student in findClassById(classId)?.students ?? const []) {
      if (student.registration == registration) return student.name;
    }
    return null;
  }

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
      unawaited(_loadStudentProfiles());
      unawaited(loadHistory());
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
    _profileLookups.add(student.registration);
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

  // -------------------------------------------- Chamada (auditoria-service)

  /// Prévia da chamada (`POST /auditorias/previa`), no formato usado pelas
  /// telas de revisão: os alunos reconhecidos entre os ativos da turma.
  Future<RoomAuditResult> previewAttendance(
    String classId,
    String imagePath,
  ) async {
    final remoteId = _requireRemoteId(classId);
    final preview = await _authorizedAudit(
      (api, session) =>
          api.preview(session, classId: remoteId, imagePath: imagePath),
    );
    _previews[classId] = preview;
    final recognized = [
      for (final student in preview.students)
        if (student.present)
          RecognizedStudent(
            studentId: '${student.studentId}',
            confidenceScore: student.confidence ?? 1,
            facialArea: const {},
          ),
    ];
    return RoomAuditResult(
      message: 'Prévia gerada pelo serviço de auditoria.',
      recognizedStudents: recognized,
      unrecognizedCount: preview.unidentifiedFaces + preview.facesOutsideClass,
      totalFacesDetected: preview.totalFaces,
    );
  }

  /// Histórico de chamadas do auditoria-service (`GET /auditorias`). As
  /// chamadas feitas só nesta sessão (sem auditoria) continuam na lista.
  Future<void> loadHistory() async {
    if (auditoriaApi == null || auth?.session == null) return;
    final generation = _generation;
    try {
      final records = await _authorizedAudit(
        (api, session) => api.list(session),
      );
      if (generation != _generation) return;
      final local = _history.where((record) => !record.isRemote).toList();
      _history
        ..clear()
        ..addAll(
          [...local, ...records.map(_recordFor)]
            ..sort((a, b) => b.date.compareTo(a.date)),
        );
      _historyError = null;
    } on AuditoriaApiException catch (error) {
      if (generation != _generation) return;
      _historyError = error.message;
    }
    notifyListeners();
  }

  /// Confirma a chamada revisada. Em turmas do turma-service, com perfil
  /// autorizado, grava a auditoria (`POST /auditorias`); senão, registra só
  /// nesta sessão.
  Future<void> completeAttendance(String classId) async {
    final classroom = findClassById(classId);
    if (classroom != null && recordsAuditFor(classId)) {
      final remoteId = classroom.remoteId!;
      final results = [
        for (final student in classroom.students)
          if (_countsForAudit(student))
            AuditResultItem(
              studentId: int.parse(student.registration),
              presence: student.status == AttendanceStatus.present
                  ? AuditPresence.present
                  : AuditPresence.possibleAbsence,
              face: student.confidence > 0
                  ? AuditFace.recognized
                  : AuditFace.notRecognized,
            ),
      ];
      if (results.isEmpty) {
        throw const AuditoriaApiException(
          'A turma não tem alunos ativos para registrar a chamada.',
        );
      }
      final record = await _authorizedAudit(
        (api, session) =>
            api.confirm(session, classId: remoteId, results: results),
      );
      _previews.remove(classId);
      _classes = _classes
          .map(
            (item) => item.id == classId
                ? item.copyWith(attendanceCompleted: true)
                : item,
          )
          .toList();
      _history.insert(0, _recordFor(record));
      notifyListeners();
      return;
    }
    _completeLocally(classId);
  }

  /// Corrige a presença de uma chamada já confirmada. [changes] traz só os
  /// alunos alterados (matrícula → presente).
  Future<void> correctAttendance(
    AttendanceRecord record, {
    required Map<String, bool> changes,
    required String justification,
  }) async {
    final auditId = record.auditId;
    if (auditId == null) {
      throw const AuditoriaApiException(
        'Só chamadas gravadas no servidor podem ser corrigidas.',
      );
    }
    if (changes.isEmpty) {
      throw const AuditoriaApiException('Altere a presença de algum aluno.');
    }
    final updated = await _authorizedAudit(
      (api, session) => api.correct(
        session,
        auditId: auditId,
        justification: justification.trim(),
        results: [
          for (final entry in changes.entries)
            AuditResultItem(
              studentId: int.parse(entry.key),
              presence: entry.value
                  ? AuditPresence.present
                  : AuditPresence.possibleAbsence,
            ),
        ],
      ),
    );
    final index = _history.indexWhere((item) => item.auditId == auditId);
    if (index >= 0) _history[index] = _recordFor(updated);
    notifyListeners();
  }

  void _completeLocally(String classId) {
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
        classId: classroom.id,
        status: AttendanceRecord.local,
        attendance: {
          for (final student in classroom.students)
            student.registration: student.status == AttendanceStatus.present,
        },
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
    _profileLookups.clear();
    _previews.clear();
    _historyError = null;
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

  /// Só vínculos ativos (e matrículas numéricas) entram na auditoria.
  static bool _countsForAudit(Student student) {
    final status = student.enrollmentStatus?.toUpperCase();
    return (status == 'ATIVO' || status == 'MATRICULADO') &&
        int.tryParse(student.registration) != null;
  }

  AttendanceRecord _recordFor(AuditRecord record) {
    final classId = record.classId == null ? null : '${record.classId}';
    final classroom = findClassById(classId);
    return AttendanceRecord(
      className: classroom?.name ?? 'Turma ${record.classId ?? '—'}',
      date: record.date,
      present: record.present,
      absent: record.absent,
      auditId: record.id,
      classId: classId,
      status: record.status.isEmpty
          ? AttendanceRecord.confirmed
          : record.status,
      attendance: {
        for (final result in record.results)
          '${result.studentId}': result.present,
      },
    );
  }

  /// Completa nome, responsável e telefone dos alunos vinculados com os dados
  /// guardados no serviço facial (a turma só conhece a matrícula).
  Future<void> _loadStudentProfiles() async {
    final facial = facialApi;
    if (facial == null) return;
    final generation = _generation;
    final pending = <String>{
      for (final classroom in _classes)
        for (final student in classroom.students)
          if (student.enrollmentStatus != null &&
              !_profileLookups.contains(student.registration))
            student.registration,
    };
    if (pending.isEmpty) return;
    _profileLookups.addAll(pending);
    final profiles = <String, StudentProfile>{};
    await Future.wait(
      pending.map((registration) async {
        try {
          final profile = await facial.getStudent(registration);
          if (profile != null) profiles[registration] = profile;
        } on FacialRecognitionException {
          // Sem o cadastro facial o aluno continua com o nome genérico.
          _profileLookups.remove(registration);
        }
      }),
    );
    if (generation != _generation || profiles.isEmpty) return;
    _classes = [
      for (final classroom in _classes)
        classroom.copyWith(
          students: [
            for (final student in classroom.students)
              if (profiles[student.registration] case final profile?)
                _withProfile(student, profile)
              else
                student,
          ],
        ),
    ];
    for (final entry in profiles.entries) {
      final known = _knownStudents[entry.key];
      if (known == null) {
        _knownStudents[entry.key] = _withProfile(
          Student(
            id: entry.key,
            name: entry.key,
            registration: entry.key,
            guardian: '',
            phone: '',
          ),
          entry.value,
        );
      }
    }
    notifyListeners();
  }

  static Student _withProfile(Student student, StudentProfile profile) =>
      student.copyWith(
        name: profile.name.trim().isEmpty ? null : profile.name.trim(),
        guardian: profile.guardian.trim().isEmpty ? null : profile.guardian,
        phone: profile.phone.trim().isEmpty ? null : profile.phone,
      );

  /// Como [_authorized], para o auditoria-service.
  Future<T> _authorizedAudit<T>(
    Future<T> Function(AuditoriaApi api, AuthSession session) request,
  ) async {
    final api = auditoriaApi;
    final auth = this.auth;
    final session = auth?.session;
    if (api == null ||
        auth == null ||
        session == null ||
        !auth.ensureValidSession()) {
      throw const AuditoriaApiException(
        'Sua sessão expirou. Entre novamente.',
        statusCode: 401,
      );
    }
    try {
      return await request(api, session);
    } on AuditoriaApiException catch (error) {
      if (error.isUnauthorized && identical(auth.session, session)) {
        auth.logout(reason: 'Sua sessão foi encerrada. Entre novamente.');
      }
      rethrow;
    }
  }

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

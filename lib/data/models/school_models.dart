import 'turma_models.dart';

enum AttendanceStatus { present, review, absent }

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.registration,
    required this.guardian,
    required this.phone,
    this.status = AttendanceStatus.present,
    this.confidence = 0,
    this.enrollmentStatus,
  });

  final String id;
  final String name;
  final String registration;
  final String guardian;
  final String phone;
  final AttendanceStatus status;
  final double confidence;

  /// Situação do vínculo no turma-service (ex.: `MATRICULADO`). Nulo quando o
  /// aluno existe só na sessão atual.
  final String? enrollmentStatus;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  Student copyWith({
    String? name,
    String? guardian,
    String? phone,
    AttendanceStatus? status,
    double? confidence,
    String? enrollmentStatus,
  }) => Student(
    id: id,
    name: name ?? this.name,
    registration: registration,
    guardian: guardian ?? this.guardian,
    phone: phone ?? this.phone,
    status: status ?? this.status,
    confidence: confidence ?? this.confidence,
    enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
  );
}

class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.name,
    required this.room,
    required this.time,
    required this.students,
    this.attendanceCompleted = false,
    this.remote,
    this.course,
  });

  /// Monta a turma exibida nas telas a partir do turma-service.
  factory SchoolClass.fromRemote(
    CourseClass remote, {
    Course? course,
    List<Student> students = const [],
    bool attendanceCompleted = false,
  }) => SchoolClass(
    id: '${remote.id}',
    name: remote.name,
    room: remote.room,
    time: ClassShift.labelOf(remote.shift),
    students: students,
    attendanceCompleted: attendanceCompleted,
    remote: remote,
    course: course,
  );

  final String id;
  final String name;
  final String room;
  final String time;
  final List<Student> students;
  final bool attendanceCompleted;

  /// Dados vindos do turma-service. Nulo para agrupamentos locais (ex.:
  /// auditoria facial sem turma).
  final CourseClass? remote;
  final Course? course;

  int? get remoteId => remote?.id;
  bool get isRemote => remote != null;

  String get courseName => course?.name ?? '';

  SchoolClass copyWith({
    String? name,
    String? room,
    String? time,
    List<Student>? students,
    bool? attendanceCompleted,
  }) => SchoolClass(
    id: id,
    name: name ?? this.name,
    room: room ?? this.room,
    time: time ?? this.time,
    students: students ?? this.students,
    attendanceCompleted: attendanceCompleted ?? this.attendanceCompleted,
    remote: remote,
    course: course,
  );
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.className,
    required this.date,
    required this.present,
    required this.absent,
    this.auditId,
    this.classId,
    this.status = AttendanceRecord.confirmed,
    this.attendance = const {},
  });

  static const confirmed = 'CONFIRMADA';
  static const corrected = 'CORRIGIDA';

  /// Chamada registrada só neste aparelho (sem auditoria no servidor).
  static const local = 'LOCAL';

  final String className;
  final DateTime date;
  final int present;
  final int absent;

  /// Identificador da auditoria no auditoria-service (nulo se for local).
  final int? auditId;

  /// Turma da chamada (id usado nas telas).
  final String? classId;

  /// `CONFIRMADA`, `CORRIGIDA` ou `LOCAL`.
  final String status;

  /// Presença de cada aluno nesta chamada, por matrícula.
  final Map<String, bool> attendance;

  bool get isRemote => auditId != null;
  int get total => present + absent;
}

import '../../core/utils/formatters.dart';

/// Turnos aceitos pelo turma-service (campo `turno`, texto livre na API).
enum ClassShift {
  matutino('MATUTINO', 'Matutino'),
  vespertino('VESPERTINO', 'Vespertino'),
  noturno('NOTURNO', 'Noturno'),
  integral('INTEGRAL', 'Integral');

  const ClassShift(this.apiName, this.label);

  final String apiName;
  final String label;

  static ClassShift? fromApi(String? value) {
    final normalized = value?.trim().toUpperCase();
    for (final shift in ClassShift.values) {
      if (shift.apiName == normalized) return shift;
    }
    return null;
  }

  /// Rótulo amigável; valores desconhecidos são exibidos como vieram.
  static String labelOf(String value) => fromApi(value)?.label ?? value;
}

/// Curso do turma-service (`CursoResposta`).
class Course {
  const Course({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    this.institutionId,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: asInt(json['id']) ?? 0,
    code: json['codigo']?.toString() ?? '',
    name: json['nome']?.toString() ?? '',
    status: json['situacao']?.toString() ?? '',
    institutionId: asInt(json['instituicaoId']),
  );

  final int id;
  final String code;
  final String name;
  final String status;
  final int? institutionId;

  bool get active => status.toUpperCase() == 'ATIVO';
}

/// Vínculo de um aluno com a turma (`VinculoAlunoResposta`).
class ClassEnrollment {
  const ClassEnrollment({required this.studentId, required this.status});

  factory ClassEnrollment.fromJson(Map<String, dynamic> json) =>
      ClassEnrollment(
        studentId: asInt(json['alunoId']) ?? 0,
        status: json['situacao']?.toString() ?? '',
      );

  final int studentId;
  final String status;
}

/// Turma do turma-service (`TurmaResposta`).
class CourseClass {
  const CourseClass({
    required this.id,
    required this.year,
    required this.name,
    required this.shift,
    required this.courseId,
    this.room = '',
    this.startDate,
    this.endDate,
    this.enrollments = const [],
  });

  factory CourseClass.fromJson(Map<String, dynamic> json) => CourseClass(
    id: asInt(json['id']) ?? 0,
    year: asInt(json['ano']) ?? 0,
    name: json['nome']?.toString() ?? '',
    shift: json['turno']?.toString() ?? '',
    room: json['sala']?.toString() ?? '',
    startDate: parseIsoDate(json['inicioAula']?.toString()),
    endDate: parseIsoDate(json['fimAula']?.toString()),
    courseId: asInt(json['cursoId']) ?? 0,
    enrollments: json['alunos'] is List
        ? (json['alunos'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ClassEnrollment.fromJson)
              .toList(growable: false)
        : const [],
  );

  final int id;
  final int year;
  final String name;
  final String shift;
  final String room;
  final DateTime? startDate;
  final DateTime? endDate;
  final int courseId;
  final List<ClassEnrollment> enrollments;
}

/// Corpo de `POST /turmas` e `PUT /turmas/{id}` (`TurmaRequisicao`).
class ClassPayload {
  const ClassPayload({
    required this.year,
    required this.name,
    required this.shift,
    required this.courseId,
    this.room,
    this.startDate,
    this.endDate,
  });

  final int year;
  final String name;
  final String shift;
  final int courseId;
  final String? room;
  final DateTime? startDate;
  final DateTime? endDate;

  Map<String, dynamic> toJson() => {
    'ano': year,
    'nome': name.trim(),
    'turno': shift,
    'sala': (room?.trim().isEmpty ?? true) ? null : room!.trim(),
    'inicioAula': startDate == null ? null : formatIsoDate(startDate!),
    'fimAula': endDate == null ? null : formatIsoDate(endDate!),
    'cursoId': courseId,
  };
}

/// Corpo de `POST /cursos` (`CursoRequisicao`).
class CoursePayload {
  const CoursePayload({
    required this.code,
    required this.name,
    required this.institutionId,
    this.status = 'ATIVO',
  });

  final String code;
  final String name;
  final String status;
  final int institutionId;

  Map<String, dynamic> toJson() => {
    'codigo': code.trim(),
    'nome': name.trim(),
    'situacao': status,
    'instituicaoId': institutionId,
  };
}

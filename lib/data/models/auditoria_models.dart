import '../../core/utils/formatters.dart';

/// Situações de presença aceitas pelo auditoria-service.
abstract final class AuditPresence {
  static const present = 'PRESENTE';
  static const possibleAbsence = 'POSSIVEL_FALTA';
}

/// Situações da face (resultado do reconhecimento) no auditoria-service.
abstract final class AuditFace {
  static const recognized = 'RECONHECIDA';
  static const notRecognized = 'NAO_RECONHECIDA';
}

/// Um aluno da prévia (`PreviaResposta.alunos`).
class AuditPreviewStudent {
  const AuditPreviewStudent({
    required this.studentId,
    required this.presence,
    this.face,
    this.confidence,
  });

  factory AuditPreviewStudent.fromJson(Map<String, dynamic> json) =>
      AuditPreviewStudent(
        studentId: asInt(json['alunoId']) ?? 0,
        presence: json['situacaoPresenca']?.toString() ?? '',
        face: json['situacaoFace']?.toString(),
        confidence: (json['confianca'] as num?)?.toDouble(),
      );

  final int studentId;
  final String presence;
  final String? face;
  final double? confidence;

  bool get present => presence == AuditPresence.present;
}

/// Resposta de `POST /auditorias/previa`: nada é gravado nesta etapa.
class AuditPreview {
  const AuditPreview({
    required this.classId,
    required this.students,
    required this.unidentifiedFaces,
    required this.facesOutsideClass,
    required this.totalFaces,
  });

  factory AuditPreview.fromJson(Map<String, dynamic> json) {
    final raw = json['alunos'];
    return AuditPreview(
      classId: asInt(json['turmaId']) ?? 0,
      students: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => AuditPreviewStudent.fromJson(e.cast()))
                .toList(growable: false)
          : const [],
      unidentifiedFaces: asInt(json['facesNaoIdentificadas']) ?? 0,
      facesOutsideClass: asInt(json['facesForaDaTurma']) ?? 0,
      totalFaces: asInt(json['totalFaces']) ?? 0,
    );
  }

  final int classId;
  final List<AuditPreviewStudent> students;
  final int unidentifiedFaces;
  final int facesOutsideClass;
  final int totalFaces;
}

/// Resultado de um aluno numa auditoria confirmada.
class AuditResultItem {
  const AuditResultItem({
    required this.studentId,
    required this.presence,
    this.face,
  });

  factory AuditResultItem.fromJson(Map<String, dynamic> json) =>
      AuditResultItem(
        studentId: asInt(json['alunoId']) ?? 0,
        presence: json['situacaoPresenca']?.toString() ?? '',
        face: json['situacaoFace']?.toString(),
      );

  final int studentId;
  final String presence;
  final String? face;

  bool get present => presence == AuditPresence.present;

  Map<String, dynamic> toJson() => {
    'alunoId': studentId,
    'situacaoPresenca': presence,
    if (face != null) 'situacaoFace': face,
  };
}

/// Auditoria gravada (`AuditoriaResposta`).
class AuditRecord {
  const AuditRecord({
    required this.id,
    required this.classId,
    required this.date,
    required this.status,
    required this.results,
    this.userId,
  });

  factory AuditRecord.fromJson(Map<String, dynamic> json) {
    final raw = json['resultados'];
    return AuditRecord(
      id: asInt(json['id']) ?? 0,
      classId: asInt(json['turmaId']),
      userId: asInt(json['usuarioId']),
      date: _dateTime(json['data'], json['horario']),
      status: json['situacao']?.toString() ?? '',
      results: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => AuditResultItem.fromJson(e.cast()))
                .toList(growable: false)
          : const [],
    );
  }

  final int id;
  final int? classId;
  final int? userId;
  final DateTime date;

  /// `CONFIRMADA` ou `CORRIGIDA`.
  final String status;
  final List<AuditResultItem> results;

  int get present => results.where((it) => it.present).length;
  int get absent => results.length - present;

  static DateTime _dateTime(Object? date, Object? time) {
    final day = DateTime.tryParse(date?.toString() ?? '');
    if (day == null) return DateTime.fromMillisecondsSinceEpoch(0);
    final parts = (time?.toString() ?? '').split(':');
    int part(int index) =>
        index < parts.length ? int.tryParse(parts[index]) ?? 0 : 0;
    return DateTime(day.year, day.month, day.day, part(0), part(1), part(2));
  }
}

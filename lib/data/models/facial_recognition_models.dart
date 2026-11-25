/// Situação de um rosto marcado na foto da sala.
enum FaceStatus {
  /// Aluno da turma reconhecido.
  recognized,

  /// Reconhecido, mas é aluno de outra turma.
  outsideClass,

  /// Rosto sem correspondência na base.
  unidentified,
}

/// Rosto detectado na foto, com a caixa em frações da imagem (0 a 1).
class DetectedFace {
  const DetectedFace({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.status,
    this.studentId,
  });

  /// Lê `{x, y, w, h}` (serviço facial) ou `{x, y, largura, altura}`
  /// (auditoria-service). Devolve nulo se a caixa não for válida.
  static DetectedFace? tryParse(
    Object? area, {
    required FaceStatus status,
    String? studentId,
  }) {
    if (area is! Map) return null;
    double? number(Object? value) => (value as num?)?.toDouble();
    final x = number(area['x']);
    final y = number(area['y']);
    final width = number(area['w'] ?? area['largura']);
    final height = number(area['h'] ?? area['altura']);
    if (x == null || y == null || width == null || height == null) return null;
    if (width <= 0 || height <= 0) return null;
    return DetectedFace(
      x: x.clamp(0, 1),
      y: y.clamp(0, 1),
      width: width.clamp(0, 1),
      height: height.clamp(0, 1),
      status: status,
      studentId: studentId,
    );
  }

  final double x;
  final double y;
  final double width;
  final double height;
  final FaceStatus status;

  /// Matrícula do aluno, quando reconhecido.
  final String? studentId;
}

class RecognizedStudent {
  const RecognizedStudent({
    required this.studentId,
    required this.confidenceScore,
    required this.facialArea,
  });

  factory RecognizedStudent.fromJson(Map<String, dynamic> json) {
    final rawArea = json['facial_area'];
    return RecognizedStudent(
      studentId: json['student_id'].toString(),
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0,
      facialArea: rawArea is Map
          ? rawArea.map((key, value) => MapEntry(key.toString(), value))
          : const {},
    );
  }

  final String studentId;
  final double confidenceScore;
  final Map<String, dynamic> facialArea;
}

class RoomAuditResult {
  const RoomAuditResult({
    required this.message,
    required this.recognizedStudents,
    required this.unrecognizedCount,
    required this.totalFacesDetected,
    this.faces = const [],
  });

  factory RoomAuditResult.fromJson(Map<String, dynamic> json) {
    final rawStudents = json['recognized_students'];
    final rawUnknown = json['unrecognized_faces'];
    final faces = <DetectedFace>[
      if (rawStudents is List)
        for (final student in rawStudents.whereType<Map>())
          ?DetectedFace.tryParse(
            student['relative_area'],
            status: FaceStatus.recognized,
            studentId: student['student_id']?.toString(),
          ),
      if (rawUnknown is List)
        for (final face in rawUnknown.whereType<Map>())
          ?DetectedFace.tryParse(
            face['relative_area'],
            status: FaceStatus.unidentified,
          ),
    ];
    return RoomAuditResult(
      faces: faces,
      message: json['message']?.toString() ?? 'Auditoria concluída.',
      recognizedStudents: rawStudents is List
          ? rawStudents
                .whereType<Map>()
                .map(
                  (student) => RecognizedStudent.fromJson(
                    student.cast<String, dynamic>(),
                  ),
                )
                .toList(growable: false)
          : const [],
      unrecognizedCount: (json['unrecognized_count'] as num?)?.toInt() ?? 0,
      totalFacesDetected: (json['total_faces_detected'] as num?)?.toInt() ?? 0,
    );
  }

  final String message;
  final List<RecognizedStudent> recognizedStudents;
  final int unrecognizedCount;
  final int totalFacesDetected;

  /// Rostos com posição na foto (vazio se o serviço não mandar a caixa).
  final List<DetectedFace> faces;
}

class StudentEnrollmentResult {
  const StudentEnrollmentResult({
    required this.message,
    required this.studentId,
  });

  factory StudentEnrollmentResult.fromJson(Map<String, dynamic> json) =>
      StudentEnrollmentResult(
        message: json['message']?.toString() ?? 'Biometria cadastrada.',
        studentId: json['student_id'].toString(),
      );

  final String message;
  final String studentId;
}

/// Dados do aluno guardados junto com a biometria no serviço facial.
class StudentProfile {
  const StudentProfile({
    required this.registration,
    this.name = '',
    this.guardian = '',
    this.phone = '',
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
    registration: json['matricula']?.toString() ?? '',
    name: json['nome']?.toString() ?? '',
    guardian: json['responsavel']?.toString() ?? '',
    phone: json['telefone']?.toString() ?? '',
  );

  final String registration;
  final String name;
  final String guardian;
  final String phone;
}

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
  });

  factory RoomAuditResult.fromJson(Map<String, dynamic> json) {
    final rawStudents = json['recognized_students'];
    return RoomAuditResult(
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

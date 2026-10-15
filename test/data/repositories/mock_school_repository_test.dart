import 'package:class_vision/data/models/facial_recognition_models.dart';
import 'package:class_vision/data/models/school_models.dart';
import 'package:class_vision/data/repositories/mock_school_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps API registrations and confidence to attendance statuses', () {
    final repository = MockSchoolRepository();
    const audit = RoomAuditResult(
      message: 'ok',
      recognizedStudents: [
        RecognizedStudent(
          studentId: '2026001',
          confidenceScore: .92,
          facialArea: {},
        ),
        RecognizedStudent(
          studentId: '2026002',
          confidenceScore: .63,
          facialArea: {},
        ),
      ],
      unrecognizedCount: 1,
      totalFacesDetected: 3,
    );

    repository.applyFacialRecognition('2a', audit);
    final students = repository.classById('2a').students;

    expect(students[0].status, AttendanceStatus.present);
    expect(students[0].confidence, .92);
    expect(students[1].status, AttendanceStatus.review);
    expect(students[1].confidence, .63);
    expect(students[2].status, AttendanceStatus.absent);
    expect(students[2].confidence, 0);
  });
}

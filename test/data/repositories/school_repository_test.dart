import 'package:class_vision/data/models/facial_recognition_models.dart';
import 'package:class_vision/data/models/school_models.dart';
import 'package:class_vision/data/repositories/school_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts without seeded school data', () {
    final repository = SchoolRepository();

    expect(repository.classes, isEmpty);
    expect(repository.history, isEmpty);
    expect(repository.profile.name, isEmpty);
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

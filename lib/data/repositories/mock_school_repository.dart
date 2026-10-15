import 'package:flutter/foundation.dart';

import '../models/facial_recognition_models.dart';
import '../models/school_models.dart';

class MockSchoolRepository extends ChangeNotifier {
  CoordinatorProfile _profile = const CoordinatorProfile(
    name: 'Marina Silva',
    email: 'coordenacao@escola.edu.br',
    school: 'Instituto Federal Goiano',
    phone: '(64) 99999-2026',
  );

  late List<SchoolClass> _classes = [
    SchoolClass(
      id: '2a',
      name: '2º Ano A',
      room: 'Sala 201',
      time: '08:00',
      students: _students,
    ),
    SchoolClass(
      id: '1b',
      name: '1º Ano B',
      room: 'Sala 104',
      time: '09:00',
      students: _students.take(4).toList(),
    ),
    SchoolClass(
      id: '3a',
      name: '3º Ano A',
      room: 'Sala 203',
      time: '10:20',
      students: _students.skip(1).toList(),
    ),
    SchoolClass(
      id: '2b',
      name: '2º Ano B',
      room: 'Sala 202',
      time: '13:30',
      students: _students,
    ),
  ];

  final List<AttendanceRecord> _history = [
    AttendanceRecord(
      className: '2º Ano A',
      date: DateTime(2026, 10, 5, 8),
      present: 29,
      absent: 3,
    ),
    AttendanceRecord(
      className: '1º Ano B',
      date: DateTime(2026, 10, 4, 9),
      present: 27,
      absent: 2,
    ),
    AttendanceRecord(
      className: '3º Ano A',
      date: DateTime(2026, 10, 3, 10, 20),
      present: 30,
      absent: 1,
    ),
  ];

  static const List<Student> _students = [
    Student(
      id: 'a1',
      name: 'Ana Beatriz',
      registration: '2026001',
      guardian: 'Luciana Souza',
      phone: '(64) 99111-1001',
      confidence: .98,
    ),
    Student(
      id: 'b2',
      name: 'Bruno Martins',
      registration: '2026002',
      guardian: 'Paulo Martins',
      phone: '(64) 99111-1002',
      confidence: .94,
    ),
    Student(
      id: 'c3',
      name: 'Carla Souza',
      registration: '2026003',
      guardian: 'Marcos Souza',
      phone: '(64) 99111-1003',
      status: AttendanceStatus.review,
      confidence: .61,
    ),
    Student(
      id: 'd4',
      name: 'Daniel Oliveira',
      registration: '2026004',
      guardian: 'Renata Oliveira',
      phone: '(64) 99111-1004',
      status: AttendanceStatus.absent,
    ),
    Student(
      id: 'e5',
      name: 'Eduarda Lima',
      registration: '2026005',
      guardian: 'Carlos Lima',
      phone: '(64) 99111-1005',
      status: AttendanceStatus.review,
      confidence: .73,
    ),
  ];

  CoordinatorProfile get profile => _profile;
  List<SchoolClass> get classes => List.unmodifiable(_classes);
  List<AttendanceRecord> get history => List.unmodifiable(_history);

  SchoolClass classById(String? id) => _classes.firstWhere(
    (item) => item.id == id,
    orElse: () => _classes.first,
  );

  void addClass({
    required String name,
    required String room,
    required String time,
  }) {
    _classes = [
      ..._classes,
      SchoolClass(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        room: room,
        time: time,
        students: const [],
      ),
    ];
    notifyListeners();
  }

  void addStudent(String classId, Student student) {
    _classes = _classes
        .map(
          (item) => item.id == classId
              ? item.copyWith(students: [...item.students, student])
              : item,
        )
        .toList();
    notifyListeners();
  }

  void updateStudentStatus(
    String classId,
    String studentId,
    AttendanceStatus status,
  ) {
    _classes = _classes
        .map(
          (item) => item.id == classId
              ? item.copyWith(
                  students: item.students
                      .map(
                        (student) => student.id == studentId
                            ? student.copyWith(status: status)
                            : student,
                      )
                      .toList(),
                )
              : item,
        )
        .toList();
    notifyListeners();
  }

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
      return item.copyWith(
        students: item.students.map((student) {
          final confidence = confidenceByRegistration[student.registration];
          if (confidence == null) {
            return student.copyWith(
              status: AttendanceStatus.absent,
              confidence: 0,
            );
          }
          return student.copyWith(
            status: confidence >= .75
                ? AttendanceStatus.present
                : AttendanceStatus.review,
            confidence: confidence,
          );
        }).toList(),
      );
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
    final classroom = classById(classId);
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

  void updateProfile(CoordinatorProfile profile) {
    _profile = profile;
    notifyListeners();
  }
}

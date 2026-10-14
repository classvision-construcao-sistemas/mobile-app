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
  });

  final String id;
  final String name;
  final String registration;
  final String guardian;
  final String phone;
  final AttendanceStatus status;
  final double confidence;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  Student copyWith({AttendanceStatus? status, double? confidence}) => Student(
    id: id,
    name: name,
    registration: registration,
    guardian: guardian,
    phone: phone,
    status: status ?? this.status,
    confidence: confidence ?? this.confidence,
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
  });

  final String id;
  final String name;
  final String room;
  final String time;
  final List<Student> students;
  final bool attendanceCompleted;

  SchoolClass copyWith({List<Student>? students, bool? attendanceCompleted}) =>
      SchoolClass(
        id: id,
        name: name,
        room: room,
        time: time,
        students: students ?? this.students,
        attendanceCompleted: attendanceCompleted ?? this.attendanceCompleted,
      );
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.className,
    required this.date,
    required this.present,
    required this.absent,
  });

  final String className;
  final DateTime date;
  final int present;
  final int absent;
}

class CoordinatorProfile {
  const CoordinatorProfile({
    required this.name,
    required this.email,
    required this.school,
    required this.phone,
  });

  final String name;
  final String email;
  final String school;
  final String phone;

  CoordinatorProfile copyWith({
    String? name,
    String? email,
    String? school,
    String? phone,
  }) => CoordinatorProfile(
    name: name ?? this.name,
    email: email ?? this.email,
    school: school ?? this.school,
    phone: phone ?? this.phone,
  );
}

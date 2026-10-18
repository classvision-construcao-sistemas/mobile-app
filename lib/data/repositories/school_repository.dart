import 'package:flutter/foundation.dart';

import '../models/facial_recognition_models.dart';
import '../models/school_models.dart';

/// Estado de interface da sessão.
///
/// A fonte persistente da biometria é exclusivamente o serviço Milvus. Este
/// repositório começa vazio e mantém apenas o contexto necessário para as telas
/// durante a sessão atual; nenhum dado fictício é pré-carregado.
class SchoolRepository extends ChangeNotifier {
  CoordinatorProfile _profile = const CoordinatorProfile(
    name: '',
    email: '',
    school: '',
    phone: '',
  );

  List<SchoolClass> _classes = [];
  final List<AttendanceRecord> _history = [];

  CoordinatorProfile get profile => _profile;
  List<SchoolClass> get classes => List.unmodifiable(_classes);
  List<AttendanceRecord> get history => List.unmodifiable(_history);

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

  /// Garante um agrupamento de sessão para auditorias iniciadas sem turma.
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

  void completeAttendance(String classId) {
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
      ),
    );
    notifyListeners();
  }

  void updateProfile(CoordinatorProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  static AttendanceStatus _statusForConfidence(double confidence) =>
      confidence >= .75 ? AttendanceStatus.present : AttendanceStatus.review;
}

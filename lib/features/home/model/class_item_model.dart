import 'class_status.dart';

/// Modelo que representa uma turma (classe) na tela inicial
class ClassItemModel {
  /// Nome da turma — ex: "2º Ano A"
  final String name;

  /// Horário da aula — ex: "08:00"
  final String time;

  /// Sala da aula — ex: "Sala 201"
  final String room;

  /// Status atual da aula
  final ClassStatus status;

  const ClassItemModel({
    required this.name,
    required this.time,
    required this.room,
    required this.status,
  });

  /// Texto formatado do horário e sala
  String get subtitle => '$time • $room';

  /// Label do badge de status
  String get statusLabel {
    switch (status) {
      case ClassStatus.now:
        return 'Agora';
      case ClassStatus.scheduled:
        return time;
      case ClassStatus.completed:
        return 'Concluída';
    }
  }
}

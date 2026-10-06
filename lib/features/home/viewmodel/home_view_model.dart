import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../model/class_item_model.dart';
import '../model/class_status.dart';
import '../model/user_model.dart';

/// ViewModel da tela inicial (Home)
///
/// Responsável por gerenciar o estado da tela inicial,
/// incluindo dados do usuário, saudação, data e lista de turmas.
class HomeViewModel extends ChangeNotifier {
  // -- Estado --

  final UserModel _user = const UserModel(
    name: 'Marina Silva',
    firstName: 'Marina',
  );

  List<ClassItemModel> _classes = [];
  bool _isLoading = true;
  int _currentNavIndex = 0;

  // -- Getters --

  UserModel get user => _user;
  List<ClassItemModel> get classes => _classes;
  bool get isLoading => _isLoading;
  int get currentNavIndex => _currentNavIndex;

  /// Saudação dinâmica baseada na hora do dia
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  /// Saudação completa — "Bom dia, Marina"
  String get greetingText => '$greeting, ${_user.firstName}';

  /// Data formatada — "Terça-feira, 1 de setembro"
  String get formattedDate {
    initializeDateFormatting('pt_BR', null);
    final now = DateTime.now();
    final weekday = DateFormat('EEEE', 'pt_BR').format(now);
    final capitalizedWeekday =
        weekday[0].toUpperCase() + weekday.substring(1);
    final day = now.day;
    final month = DateFormat('MMMM', 'pt_BR').format(now);
    return '$capitalizedWeekday, $day de $month';
  }

  // -- Métodos --

  /// Inicializa os dados da tela
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Simula carregamento de dados (futuramente virá da API)
    await Future.delayed(const Duration(milliseconds: 600));

    _classes = [
      const ClassItemModel(
        name: '2º Ano A',
        time: '08:00',
        room: 'Sala 201',
        status: ClassStatus.now,
      ),
      const ClassItemModel(
        name: '1º Ano B',
        time: '09:00',
        room: 'Sala 104',
        status: ClassStatus.scheduled,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  /// Atualiza o índice do bottom navigation
  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  /// Ação de abrir câmera
  void onOpenCamera() {
    // Navegação para a tela de câmera será implementada depois
    debugPrint('Abrir câmera para chamada com IA');
  }

  /// Ação de tap em uma turma
  void onClassTap(ClassItemModel classItem) {
    debugPrint('Turma selecionada: ${classItem.name}');
  }
}

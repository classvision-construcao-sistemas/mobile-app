import 'package:flutter/foundation.dart';

import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/auth_api.dart';

class InstitutionsViewModel extends ChangeNotifier {
  InstitutionsViewModel(this._auth);

  final AuthRepository _auth;

  List<Institution> _institutions = const [];
  bool _loading = false;
  String? _error;
  String _query = '';
  final Set<int> _busyIds = {};
  bool _disposed = false;

  bool get loading => _loading;
  String? get error => _error;
  bool get isEmpty => _institutions.isEmpty;

  bool isBusy(Institution institution) => _busyIds.contains(institution.id);

  List<Institution> get institutions {
    final query = _query.trim().toLowerCase();
    final digits = query.replaceAll(RegExp(r'[^0-9a-z]'), '');
    final filtered = _institutions
        .where(
          (institution) =>
              query.isEmpty ||
              institution.name.toLowerCase().contains(query) ||
              (digits.isNotEmpty &&
                  institution.cnpj.toLowerCase().contains(digits)),
        )
        .toList();
    filtered.sort((a, b) {
      if (a.active != b.active) return a.active ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return filtered;
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _institutions = await _auth.listInstitutions();
    } on AuthApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Ativa ou desativa. Retorna a mensagem de erro da API, se houver.
  Future<String?> setActive(
    Institution institution, {
    required bool active,
  }) async {
    if (!_busyIds.add(institution.id)) return null;
    notifyListeners();
    try {
      final updated = await _auth.setInstitutionActive(
        institution.id,
        active: active,
      );
      _institutions = [
        for (final item in _institutions)
          item.id == updated.id ? updated : item,
      ];
      return null;
    } on AuthApiException catch (error) {
      return error.message;
    } finally {
      _busyIds.remove(institution.id);
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

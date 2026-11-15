import 'package:flutter/foundation.dart';

import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/auth_api.dart';

class UsersViewModel extends ChangeNotifier {
  UsersViewModel(this._auth);

  final AuthRepository _auth;

  List<AppUser> _users = const [];
  bool _loading = false;
  String? _error;
  String _query = '';
  final Set<int> _busyIds = {};
  bool _disposed = false;

  bool get loading => _loading;
  String? get error => _error;
  bool get isEmpty => _users.isEmpty;

  bool isBusy(AppUser user) => _busyIds.contains(user.id);

  List<AppUser> get users {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _users.toList()
        : _users
              .where(
                (user) => [
                  user.name,
                  user.email,
                  user.roleLabel,
                  user.institutionName,
                ].any((value) => value.toLowerCase().contains(query)),
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
      _users = await _auth.listUsers();
    } on AuthApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Ativa ou desativa. Retorna a mensagem de erro da API, se houver.
  Future<String?> setActive(AppUser user, {required bool active}) =>
      _runOn(user, () async {
        final updated = await _auth.setUserActive(user.id, active: active);
        _users = [
          for (final item in _users) item.id == updated.id ? updated : item,
        ];
      });

  /// Exclui definitivamente. Retorna a mensagem de erro da API, se houver.
  Future<String?> delete(AppUser user) => _runOn(user, () async {
    await _auth.deleteUser(user.id);
    _users = _users.where((item) => item.id != user.id).toList();
  });

  Future<String?> _runOn(AppUser user, Future<void> Function() action) async {
    if (!_busyIds.add(user.id)) return null;
    notifyListeners();
    try {
      await action();
      return null;
    } on AuthApiException catch (error) {
      return error.message;
    } finally {
      _busyIds.remove(user.id);
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

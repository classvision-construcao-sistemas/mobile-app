import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/auth_api.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._auth);

  final AuthRepository _auth;

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  bool get loading => _loading;
  bool get obscurePassword => _obscurePassword;

  /// Mensagem do cv-authentication-service (ex.: "Email ou senha inválidos.").
  String? get error => _error;

  void togglePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Autentica no cv-authentication-service. Retorna `true` em caso de sucesso.
  Future<bool> signIn({required String email, required String password}) async {
    if (_loading) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.login(email: email, password: password);
      return true;
    } on AuthApiException catch (error) {
      _error = error.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

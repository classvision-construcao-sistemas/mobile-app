import 'package:flutter/foundation.dart';

class LoginViewModel extends ChangeNotifier {
  bool _loading = false;
  bool _obscurePassword = true;

  bool get loading => _loading;
  bool get obscurePassword => _obscurePassword;

  void togglePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> signIn() async {
    _loading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    _loading = false;
    notifyListeners();
  }
}

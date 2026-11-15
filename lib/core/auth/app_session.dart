import 'package:flutter/foundation.dart';

import '../navigation/app_routes.dart';
import 'app_user.dart';
import 'role_resolver.dart';
import 'user_role.dart';

class AppSession extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  String get homeRoute => switch (_user?.role) {
    UserRole.systemAdmin => AppRoutes.systemAdmin,
    UserRole.institutionAdmin => AppRoutes.institutionAdmin,
    UserRole.coordinator => AppRoutes.coordinator,
    null => AppRoutes.login,
  };

  void signIn(String email) {
    _user = RoleResolver.resolve(email);
    notifyListeners();
  }

  void signOut() {
    if (_user == null) return;
    _user = null;
    notifyListeners();
  }
}

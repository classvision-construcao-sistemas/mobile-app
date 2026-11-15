import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.name,
    required this.email,
    required this.role,
    this.institution,
  });

  final String name;
  final String email;
  final UserRole role;
  final String? institution;
}

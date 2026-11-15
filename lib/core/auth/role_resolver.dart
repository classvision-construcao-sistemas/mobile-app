import 'app_user.dart';
import 'user_role.dart';

abstract final class RoleResolver {
  static const _institution = 'IF Goiano — Câmpus Urutaí';

  static AppUser resolve(String email) {
    final normalizedEmail = email.trim().toLowerCase();

    return switch (normalizedEmail) {
      'arthur@classvision.app' => const AppUser(
        name: 'Arthur Silva',
        email: 'arthur@classvision.app',
        role: UserRole.systemAdmin,
      ),
      'marina.costa@ifgoiano.edu.br' => const AppUser(
        name: 'Marina Costa',
        email: 'marina.costa@ifgoiano.edu.br',
        role: UserRole.institutionAdmin,
        institution: _institution,
      ),
      _ => AppUser(
        name: 'Lucas Ferreira',
        email: normalizedEmail,
        role: UserRole.coordinator,
        institution: _institution,
      ),
    };
  }
}

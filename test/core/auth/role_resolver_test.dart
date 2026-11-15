import 'package:class_vision/core/auth/role_resolver.dart';
import 'package:class_vision/core/auth/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoleResolver', () {
    test('normalizes the system administrator email', () {
      final user = RoleResolver.resolve('  ARTHUR@CLASSVISION.APP ');

      expect(user.role, UserRole.systemAdmin);
      expect(user.name, 'Arthur Silva');
      expect(user.institution, isNull);
    });

    test('resolves the institution administrator identity', () {
      final user = RoleResolver.resolve('marina.costa@ifgoiano.edu.br');

      expect(user.role, UserRole.institutionAdmin);
      expect(user.name, 'Marina Costa');
      expect(user.institution, 'IF Goiano — Câmpus Urutaí');
    });

    test('uses the coordinator demo identity for other valid emails', () {
      final user = RoleResolver.resolve('coordenacao@escola.edu.br');

      expect(user.role, UserRole.coordinator);
      expect(user.name, 'Lucas Ferreira');
      expect(user.email, 'coordenacao@escola.edu.br');
      expect(user.institution, 'IF Goiano — Câmpus Urutaí');
    });
  });
}

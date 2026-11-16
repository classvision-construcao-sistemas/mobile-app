import 'package:class_vision/core/navigation/app_routes.dart';
import 'package:class_vision/core/navigation/route_policy.dart';
import 'package:class_vision/data/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoutePolicy', () {
    test('system administrator is isolated from every academic route', () {
      for (final route in RoutePolicy.academicRoutes) {
        expect(
          RoutePolicy.canAccess(UserRole.administrador, route),
          isFalse,
          reason: route,
        );
      }
      expect(
        RoutePolicy.canAccess(UserRole.administrador, AppRoutes.systemAdmin),
        isTrue,
      );
    });

    test('coordinator cannot access either administrative root', () {
      expect(
        RoutePolicy.canAccess(UserRole.coordenador, AppRoutes.systemAdmin),
        isFalse,
      );
      expect(
        RoutePolicy.canAccess(UserRole.coordenador, AppRoutes.institutionAdmin),
        isFalse,
      );
    });

    test('institution administrator can operate academics and settings', () {
      for (final route in RoutePolicy.academicRoutes) {
        expect(
          RoutePolicy.canAccess(UserRole.adminInstituicao, route),
          isTrue,
          reason: route,
        );
      }
      expect(
        RoutePolicy.canAccess(
          UserRole.adminInstituicao,
          AppRoutes.institutionAdmin,
        ),
        isTrue,
      );
      expect(
        RoutePolicy.canAccess(UserRole.adminInstituicao, AppRoutes.systemAdmin),
        isFalse,
      );
    });
  });
}

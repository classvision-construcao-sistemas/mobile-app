import 'package:class_vision/core/auth/user_role.dart';
import 'package:class_vision/core/navigation/app_routes.dart';
import 'package:class_vision/core/navigation/route_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoutePolicy', () {
    test('system administrator is isolated from every academic route', () {
      for (final route in RoutePolicy.academicRoutes) {
        expect(
          RoutePolicy.canAccess(UserRole.systemAdmin, route),
          isFalse,
          reason: route,
        );
      }
      expect(
        RoutePolicy.canAccess(UserRole.systemAdmin, AppRoutes.systemAdmin),
        isTrue,
      );
    });

    test('coordinator cannot access either administrative root', () {
      expect(
        RoutePolicy.canAccess(UserRole.coordinator, AppRoutes.systemAdmin),
        isFalse,
      );
      expect(
        RoutePolicy.canAccess(UserRole.coordinator, AppRoutes.institutionAdmin),
        isFalse,
      );
    });

    test('institution administrator can operate academics and settings', () {
      for (final route in RoutePolicy.academicRoutes) {
        expect(
          RoutePolicy.canAccess(UserRole.institutionAdmin, route),
          isTrue,
          reason: route,
        );
      }
      expect(
        RoutePolicy.canAccess(
          UserRole.institutionAdmin,
          AppRoutes.institutionAdmin,
        ),
        isTrue,
      );
      expect(
        RoutePolicy.canAccess(UserRole.institutionAdmin, AppRoutes.systemAdmin),
        isFalse,
      );
    });
  });
}

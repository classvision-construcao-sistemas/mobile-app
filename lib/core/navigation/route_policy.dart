import '../auth/user_role.dart';
import 'app_routes.dart';

abstract final class RoutePolicy {
  static const academicRoutes = <String>{
    AppRoutes.home,
    AppRoutes.classes,
    AppRoutes.classDetails,
    AppRoutes.camera,
    AppRoutes.processing,
    AppRoutes.review,
    AppRoutes.saved,
    AppRoutes.history,
    AppRoutes.calendar,
    AppRoutes.profile,
    AppRoutes.userRegistration,
    AppRoutes.classRegistration,
    AppRoutes.studentRegistration,
  };

  static const shellAliases = <String>{
    AppRoutes.home,
    AppRoutes.classes,
    AppRoutes.history,
    AppRoutes.calendar,
    AppRoutes.profile,
  };

  static Set<UserRole> allowedRoles(String? route) => switch (route) {
    AppRoutes.login => UserRole.values.toSet(),
    AppRoutes.systemAdmin => const {UserRole.systemAdmin},
    AppRoutes.institutionAdmin => const {UserRole.institutionAdmin},
    AppRoutes.coordinator => const {UserRole.coordinator},
    final String value when academicRoutes.contains(value) => const {
      UserRole.institutionAdmin,
      UserRole.coordinator,
    },
    _ => const {},
  };

  static bool canAccess(UserRole role, String? route) =>
      allowedRoles(route).contains(role);
}

import '../../data/models/auth_models.dart';
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
    AppRoutes.systemAdmin => const {UserRole.administrador},
    AppRoutes.institutionAdmin => const {UserRole.adminInstituicao},
    AppRoutes.coordinator => const {
      UserRole.coordenador,
      UserRole.professor,
      UserRole.secretario,
      UserRole.assistente,
    },
    final String value when academicRoutes.contains(value) => const {
      UserRole.adminInstituicao,
      UserRole.coordenador,
      UserRole.professor,
      UserRole.secretario,
      UserRole.assistente,
    },
    _ => const {},
  };

  static bool canAccess(UserRole role, String? route) =>
      allowedRoles(route).contains(role);
}

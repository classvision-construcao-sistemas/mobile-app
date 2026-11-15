import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_routes.dart';
import 'core/navigation/route_policy.dart';
import 'core/auth/app_session.dart';
import 'core/auth/user_role.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/school_repository.dart';
import 'data/services/facial_recognition_api.dart';
import 'features/ai_processing/views/ai_processing_page.dart';
import 'features/attendance/views/attendance_review_page.dart';
import 'features/attendance/views/attendance_saved_page.dart';
import 'features/auth/views/login_page.dart';
import 'features/admin/data/admin_repository.dart';
import 'features/admin/views/system_admin_shell.dart';
import 'features/institution_admin/views/institution_admin_shell.dart';
import 'features/camera/views/camera_page.dart';
import 'features/classes/views/class_details_page.dart';
import 'features/registration/views/registration_page.dart';
import 'features/shell/views/main_shell.dart';

class ClassVisionApp extends StatelessWidget {
  const ClassVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSession()),
        ChangeNotifierProvider(create: (_) => SchoolRepository.demo()),
        ChangeNotifierProvider(create: (_) => AdminRepository()),
        Provider(
          create: (_) => FacialRecognitionApi(),
          dispose: (_, api) => api.close(),
        ),
      ],
      child: Consumer<AppSession>(
        builder: (context, session, _) => MaterialApp(
          title: 'ClassVision',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.login,
          onGenerateRoute: (settings) {
            Widget roleHome({bool overview = false}) =>
                switch (session.user?.role) {
                  UserRole.systemAdmin => const SystemAdminShell(),
                  UserRole.institutionAdmin => InstitutionAdminShell(
                    initialIndex: overview ? 0 : 6,
                  ),
                  UserRole.coordinator => const MainShell(),
                  null => const LoginPage(),
                };

            if (settings.name != AppRoutes.login && !session.isAuthenticated) {
              return MaterialPageRoute<void>(
                builder: (_) => const LoginPage(),
                settings: settings,
              );
            }
            final currentRole = session.user?.role;
            if (settings.name != AppRoutes.login &&
                currentRole != null &&
                !RoutePolicy.canAccess(currentRole, settings.name)) {
              return MaterialPageRoute<void>(
                builder: (_) =>
                    roleHome(overview: settings.name == AppRoutes.home),
                settings: settings,
              );
            }
            if (currentRole != null &&
                RoutePolicy.shellAliases.contains(settings.name)) {
              return MaterialPageRoute<void>(
                builder: (_) =>
                    roleHome(overview: settings.name == AppRoutes.home),
                settings: settings,
              );
            }

            final page = switch (settings.name) {
              AppRoutes.login => const LoginPage(),
              AppRoutes.systemAdmin => const SystemAdminShell(),
              AppRoutes.institutionAdmin => const InstitutionAdminShell(),
              AppRoutes.coordinator => const MainShell(),
              AppRoutes.home ||
              AppRoutes.classes ||
              AppRoutes.history ||
              AppRoutes.profile => const MainShell(),
              AppRoutes.classDetails => ClassDetailsPage(
                classId: settings.arguments as String?,
              ),
              AppRoutes.camera => CameraPage(
                classId: settings.arguments as String?,
              ),
              AppRoutes.processing => AiProcessingPage(
                result: settings.arguments is CameraResult
                    ? settings.arguments! as CameraResult
                    : const CameraResult(classId: null, imagePath: ''),
              ),
              AppRoutes.review => switch (settings.arguments) {
                AttendanceReviewArgs args => AttendanceReviewPage(
                  classId: args.classId,
                  auditResult: args.auditResult,
                ),
                final String classId => AttendanceReviewPage(classId: classId),
                _ => const AttendanceReviewPage(),
              },
              AppRoutes.saved => AttendanceSavedPage(
                classId: settings.arguments as String?,
              ),
              AppRoutes.userRegistration => RegistrationPage(
                type: RegistrationType.user,
                editing: settings.arguments == true,
              ),
              AppRoutes.classRegistration => const RegistrationPage(
                type: RegistrationType.classroom,
              ),
              AppRoutes.studentRegistration => RegistrationPage(
                type: RegistrationType.student,
                classId: settings.arguments as String?,
              ),
              _ => roleHome(),
            };
            return MaterialPageRoute<void>(
              builder: (_) => page,
              settings: settings,
            );
          },
        ),
      ),
    );
  }
}

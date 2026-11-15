import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_routes.dart';
import 'core/auth/app_session.dart';
import 'core/auth/user_role.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/school_repository.dart';
import 'data/services/facial_recognition_api.dart';
import 'features/ai_processing/views/ai_processing_page.dart';
import 'features/attendance/views/attendance_review_page.dart';
import 'features/attendance/views/attendance_saved_page.dart';
import 'features/auth/views/login_page.dart';
import 'features/auth/views/role_landing_page.dart';
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
        ChangeNotifierProvider(create: (_) => SchoolRepository()),
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
            Widget roleHome() => switch (session.user?.role) {
              UserRole.systemAdmin => const RoleLandingPage(
                role: UserRole.systemAdmin,
              ),
              UserRole.institutionAdmin => const RoleLandingPage(
                role: UserRole.institutionAdmin,
              ),
              UserRole.coordinator => const MainShell(),
              null => const LoginPage(),
            };

            final requestedRole = switch (settings.name) {
              AppRoutes.systemAdmin => UserRole.systemAdmin,
              AppRoutes.institutionAdmin => UserRole.institutionAdmin,
              AppRoutes.coordinator => UserRole.coordinator,
              _ => null,
            };
            if (settings.name != AppRoutes.login && !session.isAuthenticated) {
              return MaterialPageRoute<void>(
                builder: (_) => const LoginPage(),
                settings: settings,
              );
            }
            if (requestedRole != null && requestedRole != session.user?.role) {
              return MaterialPageRoute<void>(
                builder: (_) => roleHome(),
                settings: settings,
              );
            }

            final page = switch (settings.name) {
              AppRoutes.login => const LoginPage(),
              AppRoutes.systemAdmin => const RoleLandingPage(
                role: UserRole.systemAdmin,
              ),
              AppRoutes.institutionAdmin => const RoleLandingPage(
                role: UserRole.institutionAdmin,
              ),
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

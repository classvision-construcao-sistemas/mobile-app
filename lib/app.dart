import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/school_repository.dart';
import 'data/services/facial_recognition_api.dart';
import 'features/ai_processing/views/ai_processing_page.dart';
import 'features/attendance/views/attendance_review_page.dart';
import 'features/attendance/views/attendance_saved_page.dart';
import 'features/auth/views/login_page.dart';
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
        ChangeNotifierProvider(create: (_) => SchoolRepository()),
        Provider(
          create: (_) => FacialRecognitionApi(),
          dispose: (_, api) => api.close(),
        ),
      ],
      child: MaterialApp(
        title: 'ClassVision',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.login,
        onGenerateRoute: (settings) {
          final page = switch (settings.name) {
            AppRoutes.login => const LoginPage(),
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
            _ => const LoginPage(),
          };
          return MaterialPageRoute<void>(
            builder: (_) => page,
            settings: settings,
          );
        },
      ),
    );
  }
}

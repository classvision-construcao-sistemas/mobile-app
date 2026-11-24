import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_routes.dart';
import 'core/navigation/route_policy.dart';
import 'core/theme/app_theme.dart';
import 'data/models/auth_models.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/school_repository.dart';
import 'data/services/auth_api.dart';
import 'data/services/facial_recognition_api.dart';
import 'data/services/turma_api.dart';
import 'features/admin/data/admin_repository.dart';
import 'features/admin/views/system_admin_shell.dart';
import 'features/ai_processing/views/ai_processing_page.dart';
import 'features/attendance/views/attendance_review_page.dart';
import 'features/attendance/views/attendance_saved_page.dart';
import 'features/auth/views/login_page.dart';
import 'features/camera/views/camera_page.dart';
import 'features/classes/views/class_details_page.dart';
import 'features/classes/views/class_form_page.dart';
import 'features/institution_admin/views/institution_admin_shell.dart';
import 'features/institutions/views/institution_form_page.dart';
import 'features/institutions/views/institutions_page.dart';
import 'features/registration/views/registration_page.dart';
import 'features/shell/views/main_shell.dart';
import 'features/users/views/user_form_page.dart';
import 'features/users/views/users_page.dart';

class ClassVisionApp extends StatefulWidget {
  const ClassVisionApp({super.key, this.authApi, this.turmaApi});

  final AuthApi? authApi;
  final TurmaApi? turmaApi;

  @override
  State<ClassVisionApp> createState() => _ClassVisionAppState();
}

class _ClassVisionAppState extends State<ClassVisionApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  late final AuthApi _authApi;
  late final AuthRepository _auth;
  late final TurmaApi _turmaApi;
  late final SchoolRepository _school;
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _authApi = widget.authApi ?? AuthApi();
    _auth = AuthRepository(api: _authApi)..addListener(_onAuthChanged);
    _turmaApi = widget.turmaApi ?? TurmaApi();
    _school = SchoolRepository(api: _turmaApi, auth: _auth);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth
      ..removeListener(_onAuthChanged)
      ..dispose();
    _school.dispose();
    if (widget.authApi == null) _authApi.close();
    if (widget.turmaApi == null) _turmaApi.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _auth.ensureValidSession();
  }

  void _onAuthChanged() {
    final authenticated = _auth.isAuthenticated;
    if (!_wasAuthenticated && authenticated) {
      // As turmas vêm do turma-service com o token recém-emitido.
      _school.loadClasses();
    }
    if (_wasAuthenticated && !authenticated) {
      _school.clear();
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (_) => false,
      );
      final reason = _auth.consumeLogoutReason();
      if (reason != null) {
        _messengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(reason)));
      }
    }
    _wasAuthenticated = authenticated;
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _auth),
      ChangeNotifierProvider.value(value: _school),
      ChangeNotifierProvider(create: (_) => AdminRepository()),
      Provider(
        create: (_) => FacialRecognitionApi(),
        dispose: (_, api) => api.close(),
      ),
    ],
    child: MaterialApp(
      title: 'ClassVision',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      initialRoute: AppRoutes.login,
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        builder: (_) => _pageFor(settings),
        settings: settings,
      ),
    ),
  );

  Widget _roleHome({bool overview = false}) => switch (_auth.role) {
    UserRole.administrador => const SystemAdminShell(),
    UserRole.adminInstituicao => InstitutionAdminShell(
      initialIndex: overview ? 0 : 6,
    ),
    UserRole.coordenador ||
    UserRole.professor ||
    UserRole.secretario ||
    UserRole.assistente => const MainShell(),
    null => const LoginPage(),
  };

  Widget _pageFor(RouteSettings settings) {
    if (settings.name != AppRoutes.login && !_auth.isAuthenticated) {
      return const LoginPage();
    }

    final role = _auth.role;
    bool allowed(bool Function(UserRole role) rule) =>
        role != null && rule(role);

    if (role != null && RoutePolicy.shellAliases.contains(settings.name)) {
      return _roleHome(overview: settings.name == AppRoutes.home);
    }
    if (RoutePolicy.academicRoutes.contains(settings.name) &&
        (role == null || !RoutePolicy.canAccess(role, settings.name))) {
      return _roleHome();
    }

    return switch (settings.name) {
      AppRoutes.login => const LoginPage(),
      AppRoutes.systemAdmin when role == UserRole.administrador =>
        const SystemAdminShell(),
      AppRoutes.institutionAdmin when role == UserRole.adminInstituicao =>
        const InstitutionAdminShell(),
      AppRoutes.coordinator
          when role != null && RoutePolicy.canAccess(role, settings.name) =>
        const MainShell(),
      AppRoutes.systemAdmin ||
      AppRoutes.institutionAdmin ||
      AppRoutes.coordinator => _roleHome(),
      AppRoutes.classDetails => ClassDetailsPage(
        classId: settings.arguments as String?,
      ),
      AppRoutes.camera => CameraPage(classId: settings.arguments as String?),
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
      AppRoutes.users when allowed((it) => it.canViewUsers) =>
        const UsersPage(),
      AppRoutes.userRegistration => _userFormFor(settings.arguments),
      AppRoutes.institutions when allowed((it) => it.canManageInstitutions) =>
        const InstitutionsPage(),
      AppRoutes.institutionRegistration => _institutionFormFor(
        settings.arguments,
      ),
      AppRoutes.classRegistration when allowed((it) => it.canManageClasses) =>
        ClassFormPage(classId: settings.arguments as String?),
      AppRoutes.studentRegistration => RegistrationPage(
        classId: settings.arguments as String?,
      ),
      AppRoutes.users ||
      AppRoutes.institutions ||
      AppRoutes.classRegistration => const _ForbiddenPage(),
      _ => _roleHome(),
    };
  }

  Widget _userFormFor(Object? arguments) {
    final session = _auth.session;
    final role = _auth.role;
    final editingSelf =
        arguments is int && arguments == session?.userId ||
        arguments is AppUser && arguments.id == session?.userId;
    if (role == null || !role.canManageUsers) return const _ForbiddenPage();
    return switch (arguments) {
      final AppUser user => UserFormPage(user: user, editingSelf: editingSelf),
      final int id => UserFormPage(userId: id, editingSelf: editingSelf),
      _ => const UserFormPage(),
    };
  }

  Widget _institutionFormFor(Object? arguments) {
    final role = _auth.role;
    final creating = arguments == null;
    final canOpen =
        role != null &&
        (creating ? role.canManageInstitutions : role.canEditInstitution);
    if (!canOpen) return const _ForbiddenPage();
    return switch (arguments) {
      final Institution institution => InstitutionFormPage(
        institution: institution,
      ),
      final int id => InstitutionFormPage(institutionId: id),
      _ => const InstitutionFormPage(),
    };
  }
}

class _ForbiddenPage extends StatelessWidget {
  const _ForbiddenPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48),
            SizedBox(height: 12),
            Text(
              'O seu perfil não tem acesso a esta área.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

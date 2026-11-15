import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/models/auth_models.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/school_repository.dart';
import 'data/services/auth_api.dart';
import 'data/services/facial_recognition_api.dart';
import 'features/ai_processing/views/ai_processing_page.dart';
import 'features/attendance/views/attendance_review_page.dart';
import 'features/attendance/views/attendance_saved_page.dart';
import 'features/auth/views/login_page.dart';
import 'features/camera/views/camera_page.dart';
import 'features/classes/views/class_details_page.dart';
import 'features/institutions/views/institution_form_page.dart';
import 'features/institutions/views/institutions_page.dart';
import 'features/registration/views/registration_page.dart';
import 'features/shell/views/main_shell.dart';
import 'features/users/views/user_form_page.dart';
import 'features/users/views/users_page.dart';

class ClassVisionApp extends StatefulWidget {
  const ClassVisionApp({super.key, this.authApi});

  /// Permite injetar um cliente do serviço de autenticação (ex.: nos testes).
  final AuthApi? authApi;

  @override
  State<ClassVisionApp> createState() => _ClassVisionAppState();
}

class _ClassVisionAppState extends State<ClassVisionApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  late final AuthApi _authApi;
  late final AuthRepository _auth;
  final _school = SchoolRepository();
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _authApi = widget.authApi ?? AuthApi();
    _auth = AuthRepository(api: _authApi)..addListener(_onAuthChanged);
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // O token vale 1 hora: ao voltar para o app, confere se ainda é válido.
    if (state == AppLifecycleState.resumed) _auth.ensureValidSession();
  }

  /// Quando a sessão termina (logout, token expirado ou recusado pela API),
  /// limpa os dados locais e volta para o login.
  void _onAuthChanged() {
    final authenticated = _auth.isAuthenticated;
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
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _school),
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
        onGenerateRoute: (settings) {
          final page = _pageFor(settings);
          return MaterialPageRoute<void>(
            builder: (_) => page,
            settings: settings,
          );
        },
      ),
    );
  }

  Widget _pageFor(RouteSettings settings) {
    // Sem sessão válida, qualquer rota protegida leva ao login.
    if (settings.name != AppRoutes.login && !_auth.isAuthenticated) {
      return const LoginPage();
    }

    final role = _auth.role;
    bool allowed(bool Function(UserRole role) rule) =>
        role != null && rule(role);

    return switch (settings.name) {
      AppRoutes.login => const LoginPage(),
      AppRoutes.home ||
      AppRoutes.classes ||
      AppRoutes.history ||
      AppRoutes.profile => const MainShell(),
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
      AppRoutes.classRegistration => const RegistrationPage(
        type: RegistrationType.classroom,
      ),
      AppRoutes.studentRegistration => RegistrationPage(
        type: RegistrationType.student,
        classId: settings.arguments as String?,
      ),
      AppRoutes.users || AppRoutes.institutions => const _ForbiddenPage(),
      _ => const MainShell(),
    };
  }

  /// Argumentos: `null` cadastra, [AppUser] ou `int` (id) edita.
  Widget _userFormFor(Object? arguments) {
    final session = _auth.session;
    final role = _auth.role;
    final editingSelf =
        arguments is int && arguments == session?.userId ||
        arguments is AppUser && arguments.id == session?.userId;
    final canOpen = role != null && role.canManageUsers;
    if (!canOpen) return const _ForbiddenPage();
    return switch (arguments) {
      final AppUser user => UserFormPage(user: user, editingSelf: editingSelf),
      final int id => UserFormPage(userId: id, editingSelf: editingSelf),
      _ => const UserFormPage(),
    };
  }

  /// Argumentos: `null` cadastra, [Institution] ou `int` (id) edita.
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

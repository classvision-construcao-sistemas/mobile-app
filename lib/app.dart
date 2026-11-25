import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_routes.dart';
import 'core/navigation/route_policy.dart';
import 'core/theme/app_theme.dart';
import 'data/models/auth_models.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/school_repository.dart';
import 'data/services/auditoria_api.dart';
import 'data/services/auth_api.dart';
import 'data/services/facial_recognition_api.dart';
import 'data/services/session_store.dart';
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
import 'features/registration/views/registration_page.dart';
import 'features/shell/views/main_shell.dart';
import 'features/users/views/user_form_page.dart';
import 'features/users/views/users_page.dart';

class ClassVisionApp extends StatefulWidget {
  const ClassVisionApp({
    super.key,
    this.authApi,
    this.turmaApi,
    this.auditoriaApi,
    this.facialApi,
    this.sessionStore,
  });

  final AuthApi? authApi;
  final TurmaApi? turmaApi;
  final AuditoriaApi? auditoriaApi;
  final FacialRecognitionApi? facialApi;

  /// Onde a sessão sobrevive ao F5 (padrão: `sessionStorage` na web).
  final SessionStore? sessionStore;

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
  late final AuditoriaApi _auditoriaApi;
  late final FacialRecognitionApi _facialApi;
  late final SchoolRepository _school;
  late final AdminRepository _admin;
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _authApi = widget.authApi ?? AuthApi();
    _auth = AuthRepository(api: _authApi, store: widget.sessionStore)
      ..addListener(_onAuthChanged);
    _turmaApi = widget.turmaApi ?? TurmaApi();
    _auditoriaApi = widget.auditoriaApi ?? AuditoriaApi();
    // O serviço facial também valida o JWT da sessão.
    _facialApi =
        widget.facialApi ??
        FacialRecognitionApi(
          authorization: () => _auth.session?.authorizationHeader,
        );
    _school = SchoolRepository(
      api: _turmaApi,
      auth: _auth,
      auditoriaApi: _auditoriaApi,
      facialApi: _facialApi,
    );
    _admin = AdminRepository(auth: _auth);
    WidgetsBinding.instance.addObserver(this);
    // Sessão retomada do recarregamento da página: carrega os dados já.
    if (_auth.isAuthenticated) _onAuthChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth
      ..removeListener(_onAuthChanged)
      ..dispose();
    _school.dispose();
    _admin.dispose();
    if (widget.authApi == null) _authApi.close();
    if (widget.turmaApi == null) _turmaApi.close();
    if (widget.auditoriaApi == null) _auditoriaApi.close();
    if (widget.facialApi == null) _facialApi.close();
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
      // Painéis de administração: instituições, usuários e serviços reais.
      if (_auth.role?.canManageUsers ?? false) _admin.load();
    }
    if (_wasAuthenticated && !authenticated) {
      _school.clear();
      _admin.clear();
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
      ChangeNotifierProvider.value(value: _admin),
      Provider.value(value: _facialApi),
    ],
    child: MaterialApp(
      title: 'ClassVision',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      initialRoute: AppRoutes.login,
      onGenerateRoute: _route,
      // Abre só a tela do endereço (ex.: `/home?aba=turmas` depois do F5),
      // sem empilhar as rotas "pai" que o Navigator criaria por padrão.
      onGenerateInitialRoutes: (name) => [_route(RouteSettings(name: name))],
    ),
  );

  Route<void> _route(RouteSettings settings) => MaterialPageRoute<void>(
    builder: (_) => _pageFor(settings),
    settings: settings,
  );

  Widget _roleHome({bool overview = false, String? tab}) =>
      switch (_auth.role) {
        UserRole.administrador => SystemAdminShell(initialTab: tab),
        UserRole.adminInstituicao => InstitutionAdminShell(
          initialIndex: overview ? 0 : 6,
          initialTab: tab,
        ),
        UserRole.coordenador ||
        UserRole.professor ||
        UserRole.secretario ||
        UserRole.assistente => MainShell(initialTab: tab),
        null => const LoginPage(),
      };

  Widget _pageFor(RouteSettings settings) {
    // O endereço pode trazer a aba do painel: `/home?aba=turmas`.
    final uri = Uri.tryParse(settings.name ?? '');
    final name = uri?.path ?? settings.name;
    final tab = uri?.queryParameters['aba'];
    if (name != AppRoutes.login && !_auth.isAuthenticated) {
      return const LoginPage();
    }
    if (name == AppRoutes.login && _auth.isAuthenticated) {
      return _roleHome(overview: true);
    }

    final role = _auth.role;
    bool allowed(bool Function(UserRole role) rule) =>
        role != null && rule(role);

    if (role != null && RoutePolicy.shellAliases.contains(name)) {
      return _roleHome(overview: name == AppRoutes.home, tab: tab);
    }
    if (RoutePolicy.academicRoutes.contains(name) &&
        (role == null || !RoutePolicy.canAccess(role, name))) {
      return _roleHome();
    }

    return switch (name) {
      AppRoutes.login => const LoginPage(),
      AppRoutes.systemAdmin when role == UserRole.administrador =>
        const SystemAdminShell(),
      AppRoutes.institutionAdmin when role == UserRole.adminInstituicao =>
        const InstitutionAdminShell(),
      AppRoutes.coordinator
          when role != null && RoutePolicy.canAccess(role, name) =>
        MainShell(initialTab: tab),
      AppRoutes.systemAdmin ||
      AppRoutes.institutionAdmin ||
      AppRoutes.coordinator => _roleHome(),
      // Telas que dependem de dados da navegação (ex.: depois do F5)
      // voltam para o painel em vez de abrir vazias.
      AppRoutes.classDetails ||
      AppRoutes.processing ||
      AppRoutes.saved when settings.arguments == null => _roleHome(),
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
          imagePath: args.imagePath,
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
      AppRoutes.institutionRegistration => _institutionFormFor(
        settings.arguments,
      ),
      AppRoutes.classRegistration when allowed((it) => it.canManageClasses) =>
        ClassFormPage(classId: settings.arguments as String?),
      AppRoutes.studentRegistration => RegistrationPage(
        classId: settings.arguments as String?,
      ),
      AppRoutes.users || AppRoutes.classRegistration => const _ForbiddenPage(),
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
      final UserFormPreset preset => UserFormPage(preset: preset),
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

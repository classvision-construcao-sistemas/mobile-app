import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/auth_models.dart' as models;
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/auth_api.dart';
import '../domain/admin_models.dart';

/// Dados dos painéis de administração (global e da instituição).
///
/// Instituições e usuários vêm do cv-authentication-service com o token da
/// sessão de [auth]; a atividade é derivada das datas de cadastro e o status
/// dos serviços é consultado direto em cada microsserviço. Não há dados
/// fictícios: sem [auth] (ex.: em testes) as listas ficam vazias.
class AdminRepository extends ChangeNotifier {
  AdminRepository({this.auth, http.Client? healthClient})
    : _healthClient = healthClient; // ignore: prefer_initializing_formals

  final AuthRepository? auth;
  final http.Client? _healthClient;

  List<models.Institution> _institutions = const [];
  List<models.AppUser> _users = const [];
  List<PlatformService> _services = const [
    PlatformService(name: 'Autenticação', health: ServiceHealth.unknown),
    PlatformService(name: 'Turmas e matrículas', health: ServiceHealth.unknown),
    PlatformService(
      name: 'Auditoria de presença',
      health: ServiceHealth.unknown,
    ),
    PlatformService(
      name: 'Reconhecimento facial',
      health: ServiceHealth.unknown,
    ),
  ];
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  bool _disposed = false;

  bool get loading => _loading;
  bool get loaded => _loaded;

  /// Mensagem do último erro ao carregar os dados.
  String? get error => _error;

  // ------------------------------------------------------------- Leitura

  /// Carrega instituições e usuários e verifica os serviços.
  Future<void> load() async {
    final auth = this.auth;
    if (auth == null || auth.session == null) return;
    _loading = true;
    _error = null;
    _notify();
    try {
      final role = auth.role;
      final institutions = await auth.listInstitutions();
      final users = (role?.canViewUsers ?? false)
          ? await auth.listUsers()
          : const <models.AppUser>[];
      _institutions = institutions;
      _users = users;
      _loaded = true;
    } on AuthApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      _notify();
    }
    unawaited(checkServices());
  }

  /// Consulta a saúde dos quatro microsserviços.
  Future<void> checkServices() async {
    final client = _healthClient ?? (auth == null ? null : http.Client());
    if (client == null) return;
    final checks = <(String, String)>[
      ('Autenticação', '${ApiConfig.authBaseUrl}/v3/api-docs'),
      ('Turmas e matrículas', '${ApiConfig.turmaBaseUrl}/v3/api-docs'),
      ('Auditoria de presença', '${ApiConfig.auditoriaBaseUrl}/v3/api-docs'),
      (
        'Reconhecimento facial',
        '${ApiConfig.facialRecognitionBaseUrl}/api/health',
      ),
    ];
    final results = await Future.wait(
      checks.map((check) async {
        try {
          final response = await client
              .get(Uri.parse(check.$2))
              .timeout(const Duration(seconds: 15));
          return PlatformService(
            name: check.$1,
            health: response.statusCode == 200
                ? ServiceHealth.operational
                : ServiceHealth.degraded,
          );
        } catch (_) {
          return PlatformService(
            name: check.$1,
            health: ServiceHealth.degraded,
          );
        }
      }),
    );
    if (_healthClient == null) client.close();
    _services = results;
    _notify();
  }

  PlatformMetrics get metrics => PlatformMetrics(
    totalInstitutions: _institutions.length,
    activeInstitutions: _institutions.where((it) => it.active).length,
    institutionAdmins: _usersWith(models.UserRole.adminInstituicao).length,
    platformUsers: _users.length,
  );

  List<Institution> get institutions =>
      [for (final institution in _institutions) _toInstitution(institution)]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<InstitutionAdminAccount> get institutionAdmins => [
    for (final user in _usersWith(models.UserRole.adminInstituicao))
      InstitutionAdminAccount(
        id: '${user.id}',
        name: user.name,
        email: user.email,
        phone: '',
        institutionId: '${user.institutionId ?? ''}',
        institutionName: user.institutionName.isNotEmpty
            ? user.institutionName
            : _institutionName(user.institutionId),
        lastAccessLabel: user.createdAt == null
            ? '—'
            : formatBrDate(user.createdAt!),
        status: user.active ? AccountStatus.active : AccountStatus.inactive,
      ),
  ];

  /// Coordenadores visíveis para a sessão (o serviço já limita à instituição
  /// de quem não é administrador geral).
  List<CoordinatorAccount> get coordinators => [
    for (final user in _usersWith(models.UserRole.coordenador))
      _toCoordinator(user),
  ];

  List<CoordinatorAccount> coordinatorsFor(String institutionId) => [
    for (final coordinator in coordinators)
      if (coordinator.institutionId == institutionId) coordinator,
  ];

  /// Cadastros recentes de instituições e usuários, do mais novo ao mais antigo.
  List<PlatformActivity> get activities {
    final events = <(DateTime, PlatformActivity)>[
      for (final institution in _institutions)
        if (institution.createdAt != null)
          (
            institution.createdAt!,
            PlatformActivity(
              id: 'institution-${institution.id}',
              institutionId: '${institution.id}',
              action: 'Instituição cadastrada',
              institution: institution.name,
              user: '—',
              whenLabel: _when(institution.createdAt!),
            ),
          ),
      for (final user in _users)
        if (user.createdAt != null)
          (
            user.createdAt!,
            PlatformActivity(
              id: 'user-${user.id}',
              institutionId: '${user.institutionId ?? ''}',
              action: '${user.roleLabel} cadastrado',
              institution: user.institutionName.isNotEmpty
                  ? user.institutionName
                  : _institutionName(user.institutionId),
              user: user.name,
              whenLabel: _when(user.createdAt!),
            ),
          ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final event in events.take(30)) event.$2];
  }

  List<PlatformActivity> activitiesFor(String institutionId) => [
    for (final activity in activities)
      if (activity.institutionId == institutionId) activity,
  ];

  List<PlatformService> get services => List.unmodifiable(_services);

  List<Institution> searchInstitutions(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return institutions;
    return institutions
        .where(
          (item) =>
              item.name.toLowerCase().contains(normalized) ||
              item.adminName.toLowerCase().contains(normalized) ||
              item.document.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  Institution? findInstitution(String id) {
    for (final institution in institutions) {
      if (institution.id == id) return institution;
    }
    return null;
  }

  // ------------------------------------------------------------- Escrita

  /// Cadastra a instituição (nome, CNPJ e telefone). O administrador da
  /// instituição é cadastrado depois, como usuário.
  Future<Institution> createInstitution(CreateInstitutionInput input) async {
    final created = await _require().createInstitution(
      models.InstitutionPayload(
        name: input.name,
        cnpj: input.document,
        phone: input.phone,
      ),
    );
    _institutions = [..._institutions, created];
    _notify();
    return _toInstitution(created);
  }

  Future<void> setInstitutionStatus(String id, InstitutionStatus status) async {
    final updated = await _require().setInstitutionActive(
      int.parse(id),
      active: status == InstitutionStatus.active,
    );
    _replaceInstitution(updated);
  }

  Future<void> updateInstitution(Institution updated) async {
    final saved = await _require().updateInstitution(
      int.parse(updated.id),
      models.InstitutionPayload(
        name: updated.name,
        cnpj: updated.document,
        phone: updated.phone,
      ),
    );
    _replaceInstitution(saved);
  }

  Future<void> setCoordinatorStatus(String id, AccountStatus status) async {
    final updated = await _require().setUserActive(
      int.parse(id),
      active: status == AccountStatus.active,
    );
    _users = [
      for (final user in _users) user.id == updated.id ? updated : user,
    ];
    _notify();
  }

  /// Descarta os dados da sessão (logout).
  void clear() {
    _institutions = const [];
    _users = const [];
    _loaded = false;
    _error = null;
    _notify();
  }

  // ------------------------------------------------------------- Interno

  AuthRepository _require() {
    final auth = this.auth;
    if (auth == null) {
      throw const AuthApiException('Sessão indisponível. Entre novamente.');
    }
    return auth;
  }

  void _replaceInstitution(models.Institution updated) {
    _institutions = [
      for (final item in _institutions) item.id == updated.id ? updated : item,
    ];
    _notify();
  }

  Iterable<models.AppUser> _usersWith(models.UserRole role) =>
      _users.where((user) => user.role == role);

  String _institutionName(int? id) {
    for (final institution in _institutions) {
      if (institution.id == id) return institution.name;
    }
    return '';
  }

  Institution _toInstitution(models.Institution source) {
    final members = _users.where((user) => user.institutionId == source.id);
    final admins = members.where(
      (user) => user.role == models.UserRole.adminInstituicao,
    );
    return Institution(
      id: '${source.id}',
      name: source.name,
      document: 'CNPJ ${source.formattedCnpj}',
      institutionalEmail: '',
      phone: source.formattedPhone,
      address: '',
      adminName: admins.isEmpty
          ? '—'
          : admins.map((user) => user.name).join(', '),
      users: members.length,
      createdAt: source.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      status: source.active
          ? InstitutionStatus.active
          : InstitutionStatus.suspended,
    );
  }

  CoordinatorAccount _toCoordinator(models.AppUser user) => CoordinatorAccount(
    id: '${user.id}',
    institutionId: '${user.institutionId ?? ''}',
    name: user.name,
    email: user.email,
    status: user.active ? AccountStatus.active : AccountStatus.inactive,
    classCount: 0,
  );

  static String _when(DateTime date) => formatBrDateTime(date);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

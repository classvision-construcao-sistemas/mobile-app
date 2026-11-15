import 'package:flutter/foundation.dart';

import '../domain/admin_models.dart';

class AdminRepository extends ChangeNotifier {
  PlatformMetrics _metrics = const PlatformMetrics(
    totalInstitutions: 48,
    activeInstitutions: 45,
    institutionAdmins: 52,
    platformUsers: 1284,
  );

  List<Institution> _institutions = [
    Institution(
      id: 'if-goiano',
      name: 'IF Goiano',
      document: 'INEP 52018437',
      institutionalEmail: 'contato.urutai@ifgoiano.edu.br',
      phone: '(64) 3465-1900',
      address: 'Urutaí — GO',
      adminName: 'Marina Costa',
      users: 782,
      createdAt: DateTime(2026, 8, 12),
      status: InstitutionStatus.active,
    ),
    Institution(
      id: 'colegio-horizonte',
      name: 'Colégio Horizonte',
      document: 'CNPJ 12.345.678/0001-90',
      institutionalEmail: 'contato@horizonte.edu.br',
      phone: '(62) 3251-4200',
      address: 'Goiânia — GO',
      adminName: 'Paulo Nunes',
      users: 318,
      createdAt: DateTime(2026, 11, 14),
      status: InstitutionStatus.active,
    ),
    Institution(
      id: 'escola-caminhos',
      name: 'Escola Caminhos',
      document: 'CNPJ 44.522.100/0001-08',
      institutionalEmail: 'contato@caminhos.edu.br',
      phone: '(62) 3440-1820',
      address: 'Anápolis — GO',
      adminName: '—',
      users: 0,
      createdAt: DateTime(2026, 11, 13),
      status: InstitutionStatus.pending,
    ),
    Institution(
      id: 'centro-vale',
      name: 'Centro Educacional Vale',
      document: 'CNPJ 08.411.055/0001-31',
      institutionalEmail: 'contato@vale.edu.br',
      phone: '(64) 3412-9000',
      address: 'Catalão — GO',
      adminName: 'Carla Mendes',
      users: 184,
      createdAt: DateTime(2026, 9, 3),
      status: InstitutionStatus.suspended,
    ),
  ];

  final List<InstitutionAdminAccount> _institutionAdmins = [
    const InstitutionAdminAccount(
      id: 'admin-marina',
      name: 'Marina Costa',
      email: 'marina.costa@ifgoiano.edu.br',
      phone: '(64) 99942-1808',
      institutionId: 'if-goiano',
      institutionName: 'IF Goiano — Câmpus Urutaí',
      lastAccessLabel: 'Hoje, 09:42',
      status: AccountStatus.active,
    ),
    const InstitutionAdminAccount(
      id: 'admin-paulo',
      name: 'Paulo Nunes',
      email: 'paulo@horizonte.edu.br',
      phone: '(62) 99814-2330',
      institutionId: 'colegio-horizonte',
      institutionName: 'Colégio Horizonte',
      lastAccessLabel: 'Convite enviado',
      status: AccountStatus.pending,
    ),
  ];

  List<CoordinatorAccount> _coordinators = const [
    CoordinatorAccount(
      id: 'coordinator-lucas',
      institutionId: 'if-goiano',
      name: 'Lucas Ferreira',
      email: 'lucas.ferreira@ifgoiano.edu.br',
      status: AccountStatus.active,
      classCount: 8,
    ),
    CoordinatorAccount(
      id: 'coordinator-juliana',
      institutionId: 'if-goiano',
      name: 'Juliana Prado',
      email: 'juliana.prado@ifgoiano.edu.br',
      status: AccountStatus.inactive,
      classCount: 6,
    ),
    CoordinatorAccount(
      id: 'coordinator-fernanda',
      institutionId: 'if-goiano',
      name: 'Fernanda Alves',
      email: 'fernanda.alves@ifgoiano.edu.br',
      status: AccountStatus.pending,
      classCount: 0,
      inviteSendCount: 1,
    ),
  ];

  List<PlatformActivity> _activities = const [
    PlatformActivity(
      id: 'activity-if-1',
      action: 'Coordenador convidado',
      institution: 'IF Goiano',
      user: 'Marina Costa',
      whenLabel: 'Hoje, 09:42',
    ),
    PlatformActivity(
      id: 'activity-1',
      action: 'Instituição criada',
      institution: 'Colégio Horizonte',
      user: 'Arthur Silva',
      whenLabel: '14 nov. 10:24',
    ),
    PlatformActivity(
      id: 'activity-2',
      action: 'Convite reenviado',
      institution: 'Escola Caminhos',
      user: 'Arthur Silva',
      whenLabel: '14 nov. 09:18',
    ),
    PlatformActivity(
      id: 'activity-3',
      action: 'Instituição suspensa',
      institution: 'Centro Educacional Vale',
      user: 'Arthur Silva',
      whenLabel: '13 nov. 17:40',
    ),
  ];

  PlatformSettings _settings = const PlatformSettings(
    inviteValidityDays: 7,
    automaticInviteReminder: true,
    outageAlerts: true,
    weeklySummary: true,
  );

  final List<PlatformService> _services = const [
    PlatformService(name: 'API principal', health: ServiceHealth.operational),
    PlatformService(
      name: 'Reconhecimento facial',
      health: ServiceHealth.operational,
    ),
    PlatformService(name: 'Envio de convites', health: ServiceHealth.degraded),
    PlatformService(name: 'Armazenamento', health: ServiceHealth.operational),
  ];

  int _sequence = 100;

  PlatformMetrics get metrics => _metrics;
  List<Institution> get institutions => List.unmodifiable(_institutions);
  List<InstitutionAdminAccount> get institutionAdmins =>
      List.unmodifiable(_institutionAdmins);
  List<CoordinatorAccount> get coordinators => List.unmodifiable(_coordinators);
  List<PlatformActivity> get activities => List.unmodifiable(_activities);
  PlatformSettings get settings => _settings;
  List<PlatformService> get services => List.unmodifiable(_services);

  List<Institution> searchInstitutions(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return institutions;
    return _institutions
        .where(
          (item) =>
              item.name.toLowerCase().contains(normalized) ||
              item.adminName.toLowerCase().contains(normalized) ||
              item.document.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  Institution? findInstitution(String id) {
    for (final institution in _institutions) {
      if (institution.id == id) return institution;
    }
    return null;
  }

  Institution createInstitution(CreateInstitutionInput input) {
    _validateInstitutionInput(input);
    final id = 'institution-${_sequence++}';
    final institution = Institution(
      id: id,
      name: input.name.trim(),
      document: input.document.trim(),
      institutionalEmail: input.institutionalEmail.trim().toLowerCase(),
      phone: input.phone.trim(),
      address: input.address.trim(),
      adminName: input.adminName.trim(),
      users: 1,
      createdAt: DateTime(2026, 11, 15),
      status: input.status,
    );
    final administrator = InstitutionAdminAccount(
      id: 'admin-${_sequence++}',
      name: input.adminName.trim(),
      email: input.adminEmail.trim().toLowerCase(),
      phone: input.adminPhone.trim(),
      institutionId: id,
      institutionName: input.name.trim(),
      lastAccessLabel: 'Convite enviado',
      status: AccountStatus.pending,
    );
    _institutions = [institution, ..._institutions];
    _institutionAdmins.insert(0, administrator);
    _activities = [
      PlatformActivity(
        id: 'activity-${_sequence++}',
        action: 'Instituição criada',
        institution: institution.name,
        user: 'Arthur Silva',
        whenLabel: 'Agora',
      ),
      ..._activities,
    ];
    _metrics = _metrics.copyWith(
      totalInstitutions: _metrics.totalInstitutions + 1,
      activeInstitutions:
          _metrics.activeInstitutions +
          (input.status == InstitutionStatus.active ? 1 : 0),
      institutionAdmins: _metrics.institutionAdmins + 1,
      platformUsers: _metrics.platformUsers + 1,
    );
    notifyListeners();
    return institution;
  }

  void setInstitutionStatus(String id, InstitutionStatus status) {
    final current = findInstitution(id);
    if (current == null || current.status == status) return;
    _institutions = _institutions
        .map((item) => item.id == id ? item.copyWith(status: status) : item)
        .toList(growable: false);
    final activeDelta = current.status == InstitutionStatus.active
        ? -1
        : status == InstitutionStatus.active
        ? 1
        : 0;
    _metrics = _metrics.copyWith(
      activeInstitutions: _metrics.activeInstitutions + activeDelta,
    );
    notifyListeners();
  }

  void updateInstitution(Institution updated) {
    final current = findInstitution(updated.id);
    if (current == null) return;
    _institutions = _institutions
        .map((item) => item.id == updated.id ? updated : item)
        .toList(growable: false);
    notifyListeners();
  }

  List<CoordinatorAccount> coordinatorsFor(String institutionId) =>
      _coordinators
          .where((item) => item.institutionId == institutionId)
          .toList(growable: false);

  List<PlatformActivity> activitiesFor(Institution institution) => _activities
      .where((item) => item.institution == institution.name)
      .toList(growable: false);

  CoordinatorAccount inviteCoordinator(
    String email, {
    String institutionId = 'if-goiano',
  }) {
    final normalized = email.trim().toLowerCase();
    if (!_isEmail(normalized)) {
      throw ArgumentError.value(email, 'email', 'Informe um e-mail válido.');
    }
    final localPart = normalized.split('@').first.replaceAll('.', ' ');
    final name = localPart
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
    final account = CoordinatorAccount(
      id: 'coordinator-${_sequence++}',
      institutionId: institutionId,
      name: name,
      email: normalized,
      status: AccountStatus.pending,
      classCount: 0,
      inviteSendCount: 1,
    );
    _coordinators = [..._coordinators, account];
    notifyListeners();
    return account;
  }

  void setCoordinatorStatus(String id, AccountStatus status) {
    if (status == AccountStatus.pending) return;
    _coordinators = _coordinators
        .map((item) => item.id == id ? item.copyWith(status: status) : item)
        .toList(growable: false);
    notifyListeners();
  }

  void resendCoordinatorInvite(String id) {
    _coordinators = _coordinators
        .map(
          (item) => item.id == id && item.status == AccountStatus.pending
              ? item.copyWith(inviteSendCount: item.inviteSendCount + 1)
              : item,
        )
        .toList(growable: false);
    notifyListeners();
  }

  void cancelCoordinatorInvite(String id) {
    _coordinators = _coordinators
        .where(
          (item) => !(item.id == id && item.status == AccountStatus.pending),
        )
        .toList(growable: false);
    notifyListeners();
  }

  void setAutomaticInviteReminder(bool value) {
    _settings = _settings.copyWith(automaticInviteReminder: value);
    notifyListeners();
  }

  void setOutageAlerts(bool value) {
    _settings = _settings.copyWith(outageAlerts: value);
    notifyListeners();
  }

  void setWeeklySummary(bool value) {
    _settings = _settings.copyWith(weeklySummary: value);
    notifyListeners();
  }

  static bool _isEmail(String value) {
    final separator = value.indexOf('@');
    return separator > 0 &&
        separator < value.length - 3 &&
        value.contains('.', separator);
  }

  static void _validateInstitutionInput(CreateInstitutionInput input) {
    final required = [
      input.name,
      input.document,
      input.institutionalEmail,
      input.phone,
      input.address,
      input.adminName,
      input.adminEmail,
      input.adminPhone,
    ];
    if (required.any((value) => value.trim().isEmpty) ||
        !_isEmail(input.institutionalEmail.trim()) ||
        !_isEmail(input.adminEmail.trim())) {
      throw ArgumentError('Preencha todos os campos obrigatórios.');
    }
  }
}

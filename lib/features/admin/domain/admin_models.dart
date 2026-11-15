enum InstitutionStatus { active, pending, suspended }

enum AccountStatus { active, inactive, pending }

enum ServiceHealth { operational, degraded }

class PlatformMetrics {
  const PlatformMetrics({
    required this.totalInstitutions,
    required this.activeInstitutions,
    required this.institutionAdmins,
    required this.platformUsers,
  });

  final int totalInstitutions;
  final int activeInstitutions;
  final int institutionAdmins;
  final int platformUsers;

  PlatformMetrics copyWith({
    int? totalInstitutions,
    int? activeInstitutions,
    int? institutionAdmins,
    int? platformUsers,
  }) => PlatformMetrics(
    totalInstitutions: totalInstitutions ?? this.totalInstitutions,
    activeInstitutions: activeInstitutions ?? this.activeInstitutions,
    institutionAdmins: institutionAdmins ?? this.institutionAdmins,
    platformUsers: platformUsers ?? this.platformUsers,
  );
}

class Institution {
  const Institution({
    required this.id,
    required this.name,
    required this.document,
    required this.institutionalEmail,
    required this.phone,
    required this.address,
    required this.adminName,
    required this.users,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String name;
  final String document;
  final String institutionalEmail;
  final String phone;
  final String address;
  final String adminName;
  final int users;
  final DateTime createdAt;
  final InstitutionStatus status;

  Institution copyWith({InstitutionStatus? status}) => Institution(
    id: id,
    name: name,
    document: document,
    institutionalEmail: institutionalEmail,
    phone: phone,
    address: address,
    adminName: adminName,
    users: users,
    createdAt: createdAt,
    status: status ?? this.status,
  );
}

class InstitutionAdminAccount {
  const InstitutionAdminAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.institutionId,
    required this.institutionName,
    required this.lastAccessLabel,
    required this.status,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String institutionId;
  final String institutionName;
  final String lastAccessLabel;
  final AccountStatus status;
}

class CoordinatorAccount {
  const CoordinatorAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.classCount,
    this.inviteSendCount = 0,
  });

  final String id;
  final String name;
  final String email;
  final AccountStatus status;
  final int classCount;
  final int inviteSendCount;

  CoordinatorAccount copyWith({AccountStatus? status, int? inviteSendCount}) =>
      CoordinatorAccount(
        id: id,
        name: name,
        email: email,
        status: status ?? this.status,
        classCount: classCount,
        inviteSendCount: inviteSendCount ?? this.inviteSendCount,
      );
}

class PlatformActivity {
  const PlatformActivity({
    required this.id,
    required this.action,
    required this.institution,
    required this.user,
    required this.whenLabel,
  });

  final String id;
  final String action;
  final String institution;
  final String user;
  final String whenLabel;
}

class PlatformSettings {
  const PlatformSettings({
    required this.inviteValidityDays,
    required this.automaticInviteReminder,
    required this.outageAlerts,
    required this.weeklySummary,
  });

  final int inviteValidityDays;
  final bool automaticInviteReminder;
  final bool outageAlerts;
  final bool weeklySummary;

  PlatformSettings copyWith({
    int? inviteValidityDays,
    bool? automaticInviteReminder,
    bool? outageAlerts,
    bool? weeklySummary,
  }) => PlatformSettings(
    inviteValidityDays: inviteValidityDays ?? this.inviteValidityDays,
    automaticInviteReminder:
        automaticInviteReminder ?? this.automaticInviteReminder,
    outageAlerts: outageAlerts ?? this.outageAlerts,
    weeklySummary: weeklySummary ?? this.weeklySummary,
  );
}

class PlatformService {
  const PlatformService({required this.name, required this.health});

  final String name;
  final ServiceHealth health;
}

class CreateInstitutionInput {
  const CreateInstitutionInput({
    required this.name,
    required this.document,
    required this.institutionalEmail,
    required this.phone,
    required this.address,
    required this.adminName,
    required this.adminEmail,
    required this.adminPhone,
    this.status = InstitutionStatus.active,
  });

  final String name;
  final String document;
  final String institutionalEmail;
  final String phone;
  final String address;
  final String adminName;
  final String adminEmail;
  final String adminPhone;
  final InstitutionStatus status;
}

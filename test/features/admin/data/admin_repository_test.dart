import 'package:class_vision/features/admin/data/admin_repository.dart';
import 'package:class_vision/features/admin/domain/admin_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminRepository', () {
    late AdminRepository repository;

    setUp(() => repository = AdminRepository());

    test('starts with the platform metrics from the reference dashboard', () {
      expect(repository.metrics.totalInstitutions, 48);
      expect(repository.metrics.activeInstitutions, 45);
      expect(repository.metrics.institutionAdmins, 52);
      expect(repository.metrics.platformUsers, 1284);
    });

    test(
      'searches institutions with normalized text and supports no results',
      () {
        expect(
          repository.searchInstitutions('  GOIANO ').single.name,
          'IF Goiano',
        );
        expect(
          repository.searchInstitutions('instituição inexistente'),
          isEmpty,
        );
      },
    );

    test('creates an institution and its first administrator atomically', () {
      final institution = repository.createInstitution(
        const CreateInstitutionInput(
          name: 'Escola Nova',
          document: '98.765.432/0001-10',
          institutionalEmail: 'contato@escolanova.edu.br',
          phone: '(62) 3333-2211',
          address: 'Rua das Flores, 100',
          adminName: 'Ana Souza',
          adminEmail: 'ana@escolanova.edu.br',
          adminPhone: '(62) 99999-2200',
        ),
      );

      expect(institution.name, 'Escola Nova');
      expect(repository.metrics.totalInstitutions, 49);
      expect(repository.metrics.institutionAdmins, 53);
      expect(
        repository.institutionAdmins.any(
          (admin) =>
              admin.name == 'Ana Souza' &&
              admin.institutionId == institution.id,
        ),
        isTrue,
      );
      expect(repository.activities.first.action, 'Instituição criada');
    });

    test('rejects incomplete institution creation without mutating data', () {
      final before = repository.metrics;

      expect(
        () => repository.createInstitution(
          const CreateInstitutionInput(
            name: '',
            document: '',
            institutionalEmail: 'inválido',
            phone: '',
            address: '',
            adminName: '',
            adminEmail: '',
            adminPhone: '',
          ),
        ),
        throwsArgumentError,
      );
      expect(repository.metrics.totalInstitutions, before.totalInstitutions);
      expect(repository.institutionAdmins.length, 2);
    });

    test('transitions coordinators between active and inactive', () {
      final lucas = repository.coordinators.firstWhere(
        (coordinator) => coordinator.name == 'Lucas Ferreira',
      );

      repository.setCoordinatorStatus(lucas.id, AccountStatus.inactive);
      expect(
        repository.coordinators
            .firstWhere((item) => item.id == lucas.id)
            .status,
        AccountStatus.inactive,
      );

      repository.setCoordinatorStatus(lucas.id, AccountStatus.active);
      expect(
        repository.coordinators
            .firstWhere((item) => item.id == lucas.id)
            .status,
        AccountStatus.active,
      );
    });

    test('invites, resends and cancels a coordinator invitation', () {
      final invited = repository.inviteCoordinator('novo@ifgoiano.edu.br');
      expect(invited.status, AccountStatus.pending);
      expect(invited.inviteSendCount, 1);

      repository.resendCoordinatorInvite(invited.id);
      expect(
        repository.coordinators
            .firstWhere((item) => item.id == invited.id)
            .inviteSendCount,
        2,
      );

      repository.cancelCoordinatorInvite(invited.id);
      expect(
        repository.coordinators.any((item) => item.id == invited.id),
        isFalse,
      );
    });

    test('rejects an invalid coordinator invitation email', () {
      expect(
        () => repository.inviteCoordinator('email-inválido'),
        throwsArgumentError,
      );
    });

    test('toggles platform invitation and notification settings', () {
      repository.setAutomaticInviteReminder(false);
      repository.setOutageAlerts(false);
      repository.setWeeklySummary(false);

      expect(repository.settings.automaticInviteReminder, isFalse);
      expect(repository.settings.outageAlerts, isFalse);
      expect(repository.settings.weeklySummary, isFalse);
    });
  });
}

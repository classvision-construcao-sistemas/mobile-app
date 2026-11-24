import 'dart:convert';

import 'package:class_vision/features/admin/data/admin_repository.dart';
import 'package:class_vision/features/admin/domain/admin_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../helpers/fake_admin_backend.dart';

void main() {
  test('has no data without a session', () async {
    final repository = AdminRepository();
    await repository.load();

    expect(repository.institutions, isEmpty);
    expect(repository.metrics.totalInstitutions, 0);
    expect(
      repository.services.every((it) => it.health == ServiceHealth.unknown),
      isTrue,
    );
  });

  test('loads institutions, users and metrics from the auth service', () async {
    final repository = AdminRepository(
      auth: await adminSession([]),
      healthClient: MockClient((_) async => http.Response('{}', 200)),
    );

    await repository.load();
    await repository.checkServices();

    expect(repository.error, isNull);
    expect(repository.metrics.totalInstitutions, 2);
    expect(repository.metrics.activeInstitutions, 1);
    expect(repository.metrics.institutionAdmins, 1);
    expect(repository.metrics.platformUsers, 2);
    final goiano = repository.findInstitution('1')!;
    expect(goiano.adminName, 'Marina Costa');
    expect(goiano.users, 2);
    expect(goiano.document, 'CNPJ 10.651.417/0005-00');
    expect(
      repository.findInstitution('2')!.status,
      InstitutionStatus.suspended,
    );
    expect(repository.searchInstitutions('  caminhos ').single.id, '2');
    expect(repository.coordinators.single.name, 'Lucas Ferreira');
    expect(repository.coordinatorsFor('1'), hasLength(1));
    expect(
      repository.activities.first.action,
      'Coordenador de curso cadastrado',
    );
    expect(
      repository.services.every((it) => it.health == ServiceHealth.operational),
      isTrue,
    );
  });

  test('marks services that do not answer as down', () async {
    final repository = AdminRepository(
      auth: await adminSession([]),
      healthClient: MockClient((_) async => http.Response('', 502)),
    );

    await repository.checkServices();

    expect(
      repository.services.every((it) => it.health == ServiceHealth.degraded),
      isTrue,
    );
  });

  test('creates institutions and changes statuses through the API', () async {
    final requests = <http.Request>[];
    final repository = AdminRepository(
      auth: await adminSession(requests),
      healthClient: MockClient((_) async => http.Response('{}', 200)),
    );
    await repository.load();

    final created = await repository.createInstitution(
      const CreateInstitutionInput(
        name: 'Escola Nova',
        document: '98.765.432/0001-10',
        institutionalEmail: '',
        phone: '(62) 3333-2211',
        address: '',
        adminName: '',
        adminEmail: '',
        adminPhone: '',
      ),
    );
    expect(created.name, 'Escola Nova');
    final post = requests.lastWhere((it) => it.method == 'POST');
    expect(jsonDecode(post.body), {
      'nome': 'Escola Nova',
      'cnpj': '98765432000110',
      'telefone': '6233332211',
    });
    expect(repository.metrics.totalInstitutions, 3);

    await repository.setInstitutionStatus('1', InstitutionStatus.suspended);
    expect(
      repository.findInstitution('1')!.status,
      InstitutionStatus.suspended,
    );

    await repository.setCoordinatorStatus('11', AccountStatus.inactive);
    expect(repository.coordinators.single.status, AccountStatus.inactive);
  });
}

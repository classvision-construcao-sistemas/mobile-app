import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_page_header.dart';

class PlatformSettingsPage extends StatelessWidget {
  const PlatformSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AdminRepository>();
    final endpoints = [
      ('Autenticação', ApiConfig.authBaseUrl),
      ('Turmas e matrículas', ApiConfig.turmaBaseUrl),
      ('Auditoria de presença', ApiConfig.auditoriaBaseUrl),
      ('Reconhecimento facial', ApiConfig.facialRecognitionBaseUrl),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      children: [
        AdminPageHeader(
          title: 'Configurações da plataforma',
          subtitle: 'Acompanhe os microsserviços que o app está usando.',
          action: OutlinedButton.icon(
            onPressed: repository.checkServices,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Verificar serviços'),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AdminSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                      icon: Icons.dns_outlined,
                      title: 'Endereços dos serviços',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Definidos no build do app (--dart-define). Todos '
                      'validam o mesmo token emitido pela autenticação.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final (name, url) in endpoints)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              url,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(child: _ServicesCard(services: repository.services)),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _ServicesCard extends StatelessWidget {
  const _ServicesCard({required this.services});
  final List<PlatformService> services;

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.monitor_heart_outlined,
          title: 'Status dos serviços',
        ),
        const SizedBox(height: 18),
        for (final service in services)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: service.health == ServiceHealth.operational
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    service.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  service.healthLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: service.health == ServiceHealth.operational
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'widgets/admin_page_header.dart';

class SystemDashboardPage extends StatelessWidget {
  const SystemDashboardPage({super.key, required this.onCreateInstitution});

  final VoidCallback onCreateInstitution;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AdminRepository>();
    final metrics = repository.metrics;

    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      children: [
        AdminPageHeader(
          title: 'Visão geral da plataforma',
          subtitle: 'Acompanhe instituições, acessos e disponibilidade do ClassVision.',
          action: AdminPrimaryButton(
            label: '+ Nova instituição',
            icon: Icons.add_rounded,
            onPressed: onCreateInstitution,
          ),
        ),
        const SizedBox(height: 34),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'INSTITUIÇÕES',
                value: '${metrics.totalInstitutions}',
                supportingText: '+4 neste mês',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: MetricCard(
                label: 'ATIVAS',
                value: '${metrics.activeInstitutions}',
                valueColor: const Color(0xFF15803D),
                supportingText: '93,7% da base',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: MetricCard(
                label: 'ADMINISTRADORES',
                value: '${metrics.institutionAdmins}',
                valueColor: AppColors.primary,
                supportingText: '3 convites pendentes',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: MetricCard(
                label: 'USUÁRIOS DA PLATAFORMA',
                value: _formatNumber(metrics.platformUsers),
                supportingText: '↑ 8,2% no período',
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        SizedBox(
          height: 326,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(flex: 2, child: _GrowthCard()),
              const SizedBox(width: 24),
              Expanded(
                child: _ServiceStatusCard(services: repository.services),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _RecentActivityCard(activities: repository.activities.take(3).toList()),
      ],
    );
  }

  static String _formatNumber(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard();

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crescimento de instituições',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: CustomPaint(
            painter: _GrowthPainter(),
            child: const SizedBox.expand(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jun', style: _axisStyle),
              Text('Jul', style: _axisStyle),
              Text('Ago', style: _axisStyle),
              Text('Set', style: _axisStyle),
              Text('Out', style: _axisStyle),
              Text('Nov', style: _axisStyle),
            ],
          ),
        ),
      ],
    ),
  );
}

const _axisStyle = TextStyle(color: Color(0xFF98A2B3), fontSize: 10);

class _GrowthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFFEEF0F3);
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path()
      ..moveTo(0, size.height * .78)
      ..cubicTo(
        size.width * .14,
        size.height * .62,
        size.width * .20,
        size.height * .68,
        size.width * .30,
        size.height * .45,
      )
      ..cubicTo(
        size.width * .45,
        size.height * .30,
        size.width * .48,
        size.height * .55,
        size.width * .62,
        size.height * .28,
      )
      ..cubicTo(
        size.width * .76,
        size.height * .08,
        size.width * .82,
        size.height * .36,
        size.width,
        size.height * .04,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ServiceStatusCard extends StatelessWidget {
  const _ServiceStatusCard({required this.services});

  final List<PlatformService> services;

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status dos serviços',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        for (final service in services)
          Expanded(
            child: Row(
              children: [
                Expanded(child: Text(service.name)),
                Text(
                  service.health == ServiceHealth.operational
                      ? 'Operacional'
                      : 'Degradado',
                  style: TextStyle(
                    color: service.health == ServiceHealth.operational
                        ? const Color(0xFF15803D)
                        : const Color(0xFFC2410C),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.activities});

  final List<PlatformActivity> activities;

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atividade recente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        for (final activity in activities)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 230,
                  child: Text(
                    activity.action,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Text(
                    activity.institution,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  activity.whenLabel,
                  style: const TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

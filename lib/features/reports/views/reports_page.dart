import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 900
        ? const _DesktopReports()
        : const _MobileReports(),
  );
}

class _DesktopReports extends StatelessWidget {
  const _DesktopReports();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
    children: [
      const Text(
        'Gestão acadêmica / Indicadores',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      const SizedBox(height: 9),
      const Text(
        'Relatórios',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      const Text(
        'Analise indicadores de presença e acompanhe tendências por turma.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 22),
      const Row(
        children: [
          Expanded(
            child: MetricCard(
              label: 'PRESENÇA GERAL',
              value: '94,2%',
              supportingText: '↑ 2,4% vs. período anterior',
              valueColor: AppColors.primary,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: MetricCard(
              label: 'ALUNOS EM ATENÇÃO',
              value: '26',
              supportingText: 'abaixo de 85% de presença',
              valueColor: AppColors.warning,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: MetricCard(
              label: 'CHAMADAS REALIZADAS',
              value: '128',
              supportingText: 'de 136 previstas',
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: MetricCard(
              label: 'CONFIANÇA DA IA',
              value: '93%',
              supportingText: 'média nas detecções',
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _Chart(title: 'Evolução da presença')),
          const SizedBox(width: 20),
          const Expanded(flex: 2, child: _AttentionList()),
        ],
      ),
      const SizedBox(height: 22),
      const _Comparison(),
    ],
  );
}

class _MobileReports extends StatelessWidget {
  const _MobileReports();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      const Text(
        'Relatórios',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      const Text(
        'Indicadores de 01 a 14 de novembro',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      const SizedBox(height: 20),
      const MetricCard(
        label: 'PRESENÇA GERAL',
        value: '94,2%',
        supportingText: '↑ 2,4%',
        valueColor: AppColors.primary,
      ),
      const SizedBox(height: 16),
      _Chart(title: 'Evolução semanal'),
      const SizedBox(height: 16),
      const Text(
        'Turmas em atenção',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      const AdminSurface(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3º Ano B',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Abaixo da meta de presença',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '82,1%',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Chart extends StatelessWidget {
  const _Chart({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in [62.0, 84.0, 72.0, 102.0])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [Text('Seg'), Text('Qua'), Text('Sex'), Text('Hoje')],
        ),
      ],
    ),
  );
}

class _AttentionList extends StatelessWidget {
  const _AttentionList();
  @override
  Widget build(BuildContext context) => const AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Turmas com menor presença',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 18),
        ListTile(title: Text('3º Ano B'), trailing: Text('82,1%')),
        ListTile(title: Text('2º Ano E'), trailing: Text('86,4%')),
        ListTile(title: Text('1º Ano B'), trailing: Text('87,2%')),
      ],
    ),
  );
}

class _Comparison extends StatelessWidget {
  const _Comparison();
  @override
  Widget build(BuildContext context) => const AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparativo por curso',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text('Informática\n95,4%', textAlign: TextAlign.center),
            ),
            Expanded(
              child: Text('Agropecuária\n93,8%', textAlign: TextAlign.center),
            ),
            Expanded(
              child: Text('Alimentos\n89,7%', textAlign: TextAlign.center),
            ),
            Expanded(
              child: Text(
                'Média institucional\n94,2%',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

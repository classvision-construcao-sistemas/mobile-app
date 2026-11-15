import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onOpenCamera,
    this.userName = 'Lucas',
    this.onOpenReview,
    this.onOpenNotifications,
    this.onViewAllPending,
  });

  final VoidCallback onOpenCamera;
  final String userName;
  final VoidCallback? onOpenReview;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onViewAllPending;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 900
        ? _DesktopDashboard(
            userName: userName,
            onOpenCamera: onOpenCamera,
            onOpenReview: onOpenReview,
            onOpenNotifications: onOpenNotifications,
            onViewAllPending: onViewAllPending,
          )
        : _MobileDashboard(
            userName: userName,
            onOpenCamera: onOpenCamera,
            onOpenReview: onOpenReview,
          ),
  );
}

class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({
    required this.userName,
    required this.onOpenCamera,
    this.onOpenReview,
    this.onOpenNotifications,
    this.onViewAllPending,
  });
  final String userName;
  final VoidCallback onOpenCamera;
  final VoidCallback? onOpenReview;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onViewAllPending;

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('home-desktop'),
    padding: const EdgeInsets.fromLTRB(38, 30, 38, 40),
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bom dia, $userName',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Acompanhe a presença do Instituto Federal Goiano — Câmpus Urutaí.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Buscar...',
              ),
            ),
          ),
          const SizedBox(width: 14),
          IconButton.filledTonal(
            onPressed: onOpenNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primary,
            child: Text('LF'),
          ),
        ],
      ),
      const SizedBox(height: 26),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Resumo de hoje',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '14 nov. 2026  ⌄',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      const Row(
        children: [
          Expanded(
            child: MetricCard(
              label: 'Presença média',
              value: '94,2%',
              supportingText: '↑ 2,4% mês',
              valueColor: AppColors.primary,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              label: 'Chamadas realizadas',
              value: '128',
              supportingText: 'de 136 aulas previstas',
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              label: 'Alunos ativos',
              value: '742',
              supportingText: 'em 28 turmas',
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              label: 'Pendências',
              value: '8',
              supportingText: 'requerem revisão',
              valueColor: AppColors.warning,
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(flex: 3, child: _PresenceChart()),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: _ReviewPanel(
              onOpenReview: onOpenReview ?? onOpenCamera,
              onViewAllPending: onViewAllPending,
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      const _RecentActivity(),
    ],
  );
}

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({
    required this.userName,
    required this.onOpenCamera,
    this.onOpenReview,
  });
  final String userName;
  final VoidCallback onOpenCamera;
  final VoidCallback? onOpenReview;

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('home-mobile'),
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $userName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sábado, 14 de novembro',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primary,
            child: Text('LF', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      const SizedBox(height: 24),
      const Text(
        'Resumo de hoje',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      const AdminSurface(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRESENÇA MÉDIA',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    '94,2%',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PENDÊNCIAS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    '8',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Chamadas para revisar',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 11),
      _MobileReviewCard(
        title: '2º Ano A · Matemática',
        subtitle: '6 alunos com baixa confiança',
        action: 'Revisar',
        onTap: onOpenReview ?? onOpenCamera,
      ),
      const SizedBox(height: 10),
      _MobileReviewCard(
        title: '3º Ano B · Química',
        subtitle: 'Chamada aguardando confirmação',
        action: 'Abrir',
        onTap: onOpenReview ?? onOpenCamera,
      ),
      const SizedBox(height: 24),
      const Text(
        'Turmas em andamento',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 11),
      const AdminSurface(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
              child: Text('2A', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2º Ano A',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Rafael Mendes · Sala 204',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '96,8%',
              style: TextStyle(
                color: Color(0xFF15803D),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _PresenceChart extends StatelessWidget {
  const _PresenceChart();
  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Presença ao longo da semana',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'Média de presença por dia letivo',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final value in [84.0, 91.0, 88.0, 94.0, 92.0, 96.0])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    child: Container(
                      height: value,
                      decoration: BoxDecoration(
                        color: value == 96
                            ? AppColors.primary
                            : AppColors.primarySoft,
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
        const SizedBox(height: 9),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('Seg'),
            Text('Ter'),
            Text('Qua'),
            Text('Qui'),
            Text('Sex'),
            Text('Sáb'),
          ],
        ),
      ],
    ),
  );
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({required this.onOpenReview, this.onViewAllPending});
  final VoidCallback onOpenReview;
  final VoidCallback? onViewAllPending;
  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chamadas para revisar',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          '8 registros aguardando validação',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 14),
        _DesktopReviewRow(
          title: '2º Ano A — Matemática',
          subtitle: '6 alunos com baixa confiança',
          onTap: onOpenReview,
        ),
        const Divider(),
        _DesktopReviewRow(
          title: '3º Ano B — Química',
          subtitle: 'Chamada não confirmada',
          onTap: onOpenReview,
        ),
        TextButton(
          onPressed: onViewAllPending,
          child: const Text('Ver todas as pendências →'),
        ),
      ],
    ),
  );
}

class _DesktopReviewRow extends StatelessWidget {
  const _DesktopReviewRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      TextButton(onPressed: onTap, child: const Text('Revisar')),
    ],
  );
}

class _MobileReviewCard extends StatelessWidget {
  const _MobileReviewCard({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AdminSurface(
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();
  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atividade recente',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Acompanhe as últimas atualizações da instituição',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 14),
        for (final item in const [
          (
            'Chamada confirmada — 1º Ano C',
            'Prof. Rafael Mendes confirmou 31 presenças',
            'há 12 min',
          ),
          (
            'Novo aluno cadastrado — 2º Ano A',
            'Beatriz Nogueira foi adicionada à turma',
            'há 38 min',
          ),
          (
            'Alerta de baixa presença — 3º Ano B',
            'A turma atingiu 82% de média no período',
            'há 1 h',
          ),
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppColors.primarySoft,
              child: Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            title: Text(
              item.$1,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            subtitle: Text(item.$2, style: const TextStyle(fontSize: 10)),
            trailing: Text(
              item.$3,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
      ],
    ),
  );
}

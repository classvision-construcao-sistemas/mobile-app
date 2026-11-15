import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, this.onOpenReview});
  final VoidCallback? onOpenReview;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 900
        ? _DesktopAttendance(onOpenReview: onOpenReview)
        : _MobileAttendance(onOpenReview: onOpenReview),
  );
}

class _DesktopAttendance extends StatelessWidget {
  const _DesktopAttendance({this.onOpenReview});
  final VoidCallback? onOpenReview;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
    children: [
      const Text(
        'Gestão acadêmica / Controle de presença',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      const SizedBox(height: 9),
      const Text(
        'Chamadas',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      const Text(
        'Acompanhe chamadas confirmadas, pendentes e registros que exigem revisão.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 22),
      const Row(
        children: [
          Expanded(
            child: MetricCard(
              label: 'TOTAL NO PERÍODO',
              value: '128',
              supportingText: 'chamadas registradas',
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              label: 'CONFIRMADAS',
              value: '116',
              supportingText: '90,6% do total',
              valueColor: AppColors.success,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              label: 'EM REVISÃO',
              value: '8',
              supportingText: 'requerem sua atenção',
              valueColor: AppColors.warning,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              label: 'PENDENTES',
              value: '4',
              supportingText: 'sem confirmação',
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      AdminSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 20, 22, 12),
              child: Text(
                'Histórico de chamadas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            _AttendanceRow(
              date: '14 nov. · 08:05',
              className: '2º Ano A',
              teacher: 'Rafael Mendes',
              presence: '31 de 32',
              status: 'Em revisão',
              onTap: onOpenReview,
            ),
            const _AttendanceRow(
              date: '14 nov. · 07:52',
              className: '1º Ano C',
              teacher: 'Camila Ribeiro',
              presence: '30 de 31',
              status: 'Confirmada',
            ),
            const _AttendanceRow(
              date: '13 nov. · 10:18',
              className: '3º Ano B',
              teacher: 'João Vitor Lima',
              presence: '24 de 29',
              status: 'Pendente',
            ),
          ],
        ),
      ),
    ],
  );
}

class _MobileAttendance extends StatelessWidget {
  const _MobileAttendance({this.onOpenReview});
  final VoidCallback? onOpenReview;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      const Text(
        'Chamadas',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      const Text(
        'Histórico de presença e pendências',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      const SizedBox(height: 18),
      const Align(
        alignment: Alignment.centerLeft,
        child: Chip(label: Text('Esta semana  ⌄')),
      ),
      const SizedBox(height: 18),
      const Text(
        'Requer revisão',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      _MobileAttendanceCard(
        title: '2º Ano A · Matemática',
        subtitle: 'Hoje, 08:05 · 31 de 32 detectados',
        status: 'Em revisão',
        action: 'Abrir',
        onTap: onOpenReview,
      ),
      const SizedBox(height: 20),
      const Text(
        'Confirmadas',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      const _MobileAttendanceCard(
        title: '1º Ano C · Biologia',
        subtitle: 'Hoje, 07:52 · 30 de 31 presentes',
        status: 'Confirmada',
      ),
      const SizedBox(height: 10),
      const _MobileAttendanceCard(
        title: '3º Ano B · Química',
        subtitle: '13 nov., 10:18 · 24 de 29 presentes',
        status: 'Pendente',
      ),
    ],
  );
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.date,
    required this.className,
    required this.teacher,
    required this.presence,
    required this.status,
    this.onTap,
  });
  final String date;
  final String className;
  final String teacher;
  final String presence;
  final String status;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        Expanded(child: Text(date)),
        Expanded(
          child: Text(
            className,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Text(teacher)),
        Expanded(child: Text(presence)),
        Expanded(
          child: Text(
            status,
            style: TextStyle(
              color: status == 'Confirmada'
                  ? AppColors.success
                  : AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(status == 'Em revisão' ? 'Revisar →' : 'Ver →'),
        ),
      ],
    ),
  );
}

class _MobileAttendanceCard extends StatelessWidget {
  const _MobileAttendanceCard({
    required this.title,
    required this.subtitle,
    required this.status,
    this.action,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final String status;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AdminSurface(
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                status,
                style: TextStyle(
                  color: status == 'Confirmada'
                      ? AppColors.success
                      : AppColors.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            if (action != null)
              TextButton(onPressed: onTap, child: Text(action!)),
          ],
        ),
      ],
    ),
  );
}

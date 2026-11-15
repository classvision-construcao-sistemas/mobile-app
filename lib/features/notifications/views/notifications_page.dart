import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
    children: [
      Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const Expanded(
            child: Text(
              'Notificações',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      const Padding(
        padding: EdgeInsets.only(left: 48),
        child: Text(
          '3 notificações não lidas',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        'HOJE',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      const _Notification(
        title: 'Chamada precisa de revisão',
        subtitle: '2º Ano A possui 6 detecções incertas.',
        when: 'há 12 min',
        warning: true,
      ),
      const _Notification(
        title: 'Baixa presença identificada',
        subtitle: '3º Ano B atingiu 82,1% no período.',
        when: 'há 1 h',
        warning: true,
      ),
      const SizedBox(height: 16),
      const Text(
        'ONTEM',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      const _Notification(
        title: 'Chamada confirmada',
        subtitle: '1º Ano C foi confirmado por Camila Ribeiro.',
        when: 'ontem, 08:14',
      ),
      const _Notification(
        title: 'Novo aluno cadastrado',
        subtitle: 'Beatriz Nogueira entrou no 2º Ano A.',
        when: 'ontem, 07:42',
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () {},
        child: const Text('Marcar todas como lidas'),
      ),
    ],
  );
}

class _Notification extends StatelessWidget {
  const _Notification({
    required this.title,
    required this.subtitle,
    required this.when,
    this.warning = false,
  });
  final String title;
  final String subtitle;
  final String when;
  final bool warning;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: AdminSurface(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: warning
                ? AppColors.warningLight
                : AppColors.successLight,
            child: Icon(
              warning ? Icons.warning_amber_rounded : Icons.check_rounded,
              color: warning ? AppColors.warning : AppColors.success,
              size: 19,
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
                    fontWeight: FontWeight.w800,
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
          Text(
            when,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
          ),
        ],
      ),
    ),
  );
}

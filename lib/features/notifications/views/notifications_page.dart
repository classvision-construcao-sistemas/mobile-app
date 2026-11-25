import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _Item {
  const _Item(this.title, this.subtitle, this.date, {this.warning = false});
  final String title;
  final String subtitle;
  final DateTime date;
  final bool warning;
}

/// Avisos gerados a partir dos dados reais: turmas sem chamada hoje, turmas
/// abaixo da meta de presença e as últimas chamadas registradas.
class _NotificationsPageState extends State<NotificationsPage> {
  bool _allRead = false;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _when(DateTime date, DateTime now) {
    final diff = now.difference(date);
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (_sameDay(date, now)) {
      if (diff.inMinutes < 1) return 'agora';
      if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
      return 'há ${diff.inHours} h';
    }
    if (_sameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'ontem, $time';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}, $time';
  }

  List<_Item> _items(SchoolRepository? repository, DateTime now) {
    if (repository == null) return const [];
    final history = repository.history;
    final items = <_Item>[];
    for (final classroom in repository.classes) {
      if (!classroom.isRemote || classroom.students.isEmpty) continue;
      final records = history.where((it) => it.classId == classroom.id);
      if (!records.any((it) => _sameDay(it.date, now)) &&
          !classroom.attendanceCompleted) {
        items.add(
          _Item(
            'Chamada pendente',
            '${classroom.name} ainda não tem chamada hoje.',
            DateTime(now.year, now.month, now.day),
            warning: true,
          ),
        );
      }
      final total = records.fold<int>(0, (sum, it) => sum + it.total);
      if (total > 0) {
        final rate =
            records.fold<int>(0, (sum, it) => sum + it.present) / total;
        if (rate < .85) {
          items.add(
            _Item(
              'Baixa presença identificada',
              '${classroom.name} está com '
                  '${(rate * 100).toStringAsFixed(1).replaceAll('.', ',')}% de presença.',
              records.first.date,
              warning: true,
            ),
          );
        }
      }
    }
    for (final record in history.take(5)) {
      items.add(
        _Item(
          record.status == AttendanceRecord.corrected
              ? 'Chamada corrigida'
              : 'Chamada confirmada',
          '${record.className}: ${record.present} de ${record.total} presentes.',
          record.date,
        ),
      );
    }
    return items..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final items = _items(context.watch<SchoolRepository?>(), now);
    final unread = _allRead ? 0 : items.length;
    final today = items.where((it) => _sameDay(it.date, now)).toList();
    final earlier = items.where((it) => !_sameDay(it.date, now)).toList();

    Widget section(String label, List<_Item> list) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in list)
          _Notification(
            title: item.title,
            subtitle: item.subtitle,
            when: _when(item.date, now),
            warning: item.warning,
          ),
        const SizedBox(height: 16),
      ],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
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
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Text(
            unread == 0
                ? 'Nenhuma notificação não lida'
                : '$unread notificação(ões) não lida(s)',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 22),
        if (items.isEmpty)
          const AdminSurface(
            child: Text(
              'Nenhuma notificação por enquanto.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        if (today.isNotEmpty) section('HOJE', today),
        if (earlier.isNotEmpty) section('ANTERIORES', earlier),
        TextButton(
          onPressed: _allRead || items.isEmpty
              ? null
              : () => setState(() => _allRead = true),
          child: Text(
            _allRead || items.isEmpty
                ? 'Tudo em dia'
                : 'Marcar todas como lidas',
          ),
        ),
      ],
    );
  }
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
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            when,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

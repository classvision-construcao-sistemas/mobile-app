import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, this.onOpenReview});
  final ValueChanged<String>? onOpenReview;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<SchoolRepository>();
    final records = repository.history;
    String? idFor(AttendanceRecord record) => repository.classes
        .where((item) => item.name == record.className)
        .firstOrNull
        ?.id;
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 900
          ? _DesktopAttendance(
              records: records,
              idFor: idFor,
              onOpenReview: onOpenReview,
            )
          : _MobileAttendance(
              records: records,
              idFor: idFor,
              onOpenReview: onOpenReview,
            ),
    );
  }
}

class _DesktopAttendance extends StatelessWidget {
  const _DesktopAttendance({
    required this.records,
    required this.idFor,
    this.onOpenReview,
  });
  final List<AttendanceRecord> records;
  final String? Function(AttendanceRecord) idFor;
  final ValueChanged<String>? onOpenReview;

  VoidCallback? _callbackFor(AttendanceRecord record) {
    final id = idFor(record);
    if (id == null || onOpenReview == null) return null;
    return () => onOpenReview!(id);
  }

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
            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Text('Nenhuma chamada registrada nesta sessão.'),
              )
            else
              for (var index = 0; index < records.length; index++)
                _AttendanceRow(
                  record: records[index],
                  status: index == 0 ? 'Em revisão' : 'Confirmada',
                  onTap: _callbackFor(records[index]),
                ),
          ],
        ),
      ),
    ],
  );
}

class _MobileAttendance extends StatelessWidget {
  const _MobileAttendance({
    required this.records,
    required this.idFor,
    this.onOpenReview,
  });
  final List<AttendanceRecord> records;
  final String? Function(AttendanceRecord) idFor;
  final ValueChanged<String>? onOpenReview;

  VoidCallback? _callbackFor(AttendanceRecord record) {
    final id = idFor(record);
    if (id == null || onOpenReview == null) return null;
    return () => onOpenReview!(id);
  }

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
      if (records.isEmpty)
        const AdminSurface(
          child: Center(
            child: Text('Nenhuma chamada registrada nesta sessão.'),
          ),
        )
      else ...[
        const Text(
          'Requer revisão',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _MobileAttendanceCard(
          record: records.first,
          status: 'Em revisão',
          action: 'Abrir',
          onTap: _callbackFor(records.first),
        ),
        if (records.length > 1) ...[
          const SizedBox(height: 20),
          const Text(
            'Confirmadas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final record in records.skip(1)) ...[
            _MobileAttendanceCard(record: record, status: 'Confirmada'),
            const SizedBox(height: 10),
          ],
        ],
      ],
    ],
  );
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.record,
    required this.status,
    this.onTap,
  });
  final AttendanceRecord record;
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
        Expanded(child: Text(_dateLabel(record.date))),
        Expanded(
          child: Text(
            record.className,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const Expanded(child: Text('Professor responsável')),
        Expanded(
          child: Text('${record.present} de ${record.present + record.absent}'),
        ),
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
    required this.record,
    required this.status,
    this.action,
    this.onTap,
  });
  final AttendanceRecord record;
  final String status;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AdminSurface(
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${record.className} · ${_subject(record.className)}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          '${_dateLabel(record.date)} · ${record.present} de ${record.present + record.absent} presentes',
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

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} nov. · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _subject(String className) => switch (className) {
  '2º Ano A' => 'Matemática',
  '1º Ano C' => 'Biologia',
  '3º Ano B' => 'Química',
  _ => 'Chamada',
};

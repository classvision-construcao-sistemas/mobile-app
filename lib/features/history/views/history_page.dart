import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';
import 'attendance_correction_page.dart';

/// Histórico de chamadas: auditorias gravadas no auditoria-service e as
/// chamadas feitas só nesta sessão (turmas locais ou perfis sem registro).
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, this.onOpenReview});
  final ValueChanged<String>? onOpenReview;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<SchoolRepository>();
    final records = repository.history;
    _RecordAction? actionFor(AttendanceRecord record) {
      // Chamada gravada no servidor: corrigida com justificativa.
      if (repository.canCorrect(record)) {
        return (
          label: 'Corrigir',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => AttendanceCorrectionPage(record: record),
            ),
          ),
        );
      }
      // Chamada local ainda pode ser revisada na tela de conferência.
      final id = record.classId;
      if (record.isRemote || id == null || onOpenReview == null) return null;
      if (repository.findClassById(id) == null) return null;
      return (label: 'Revisar', onTap: () => onOpenReview!(id));
    }

    final data = _HistoryData(
      records: records,
      error: repository.historyError,
      actionFor: actionFor,
      onRefresh: repository.loadHistory,
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 900
          ? _DesktopAttendance(data: data)
          : _MobileAttendance(data: data),
    );
  }
}

class _HistoryData {
  const _HistoryData({
    required this.records,
    required this.error,
    required this.actionFor,
    required this.onRefresh,
  });

  final List<AttendanceRecord> records;
  final String? error;
  final _RecordAction? Function(AttendanceRecord) actionFor;
  final Future<void> Function() onRefresh;

  int count(String status) =>
      records.where((record) => record.status == status).length;
}

String _statusLabel(AttendanceRecord record) => switch (record.status) {
  AttendanceRecord.corrected => 'Corrigida',
  AttendanceRecord.local => 'Só nesta sessão',
  _ => 'Confirmada',
};

Color _statusColor(AttendanceRecord record) => switch (record.status) {
  AttendanceRecord.corrected => AppColors.info,
  AttendanceRecord.local => AppColors.warning,
  _ => AppColors.success,
};

String _percent(int part, int total) => total == 0
    ? '—'
    : '${(part * 100 / total).toStringAsFixed(1).replaceAll('.', ',')}% do total';

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.warningLight,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      'Não foi possível carregar o histórico do servidor: $message',
      style: const TextStyle(
        color: Color(0xFFB45309),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _DesktopAttendance extends StatelessWidget {
  const _DesktopAttendance({required this.data});
  final _HistoryData data;

  @override
  Widget build(BuildContext context) {
    final records = data.records;
    final total = records.length;
    final confirmed = data.count(AttendanceRecord.confirmed);
    final corrected = data.count(AttendanceRecord.corrected);
    final local = data.count(AttendanceRecord.local);
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
      children: [
        const Text(
          'Gestão acadêmica / Controle de presença',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Chamadas',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
            OutlinedButton.icon(
              onPressed: data.onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Atualizar'),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Acompanhe as chamadas confirmadas e as corrigidas pela coordenação.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 22),
        if (data.error case final error?) _ErrorBanner(error),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'TOTAL',
                value: '$total',
                supportingText: 'chamadas registradas',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                label: 'CONFIRMADAS',
                value: '$confirmed',
                supportingText: _percent(confirmed, total),
                valueColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                label: 'CORRIGIDAS',
                value: '$corrected',
                supportingText: 'com justificativa',
                valueColor: AppColors.info,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MetricCard(
                label: 'SÓ NESTA SESSÃO',
                value: '$local',
                supportingText: 'não gravadas no servidor',
                valueColor: AppColors.warning,
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
                  child: Text('Nenhuma chamada registrada.'),
                )
              else
                for (final record in records)
                  _AttendanceRow(
                    record: record,
                    action: data.actionFor(record),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileAttendance extends StatelessWidget {
  const _MobileAttendance({required this.data});
  final _HistoryData data;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: data.onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'Chamadas',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Histórico de presença das turmas',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 18),
        if (data.error case final error?) _ErrorBanner(error),
        if (data.records.isEmpty)
          const AdminSurface(
            child: Center(child: Text('Nenhuma chamada registrada.')),
          )
        else
          for (final record in data.records) ...[
            _MobileAttendanceCard(
              record: record,
              action: data.actionFor(record),
            ),
            const SizedBox(height: 10),
          ],
      ],
    ),
  );
}

typedef _RecordAction = ({String label, VoidCallback onTap});

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.record, this.action});
  final AttendanceRecord record;
  final _RecordAction? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        Expanded(child: Text(formatBrDateTime(record.date))),
        Expanded(
          child: Text(
            record.className,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Text('${record.present} de ${record.total}')),
        Expanded(
          child: Text(
            _statusLabel(record),
            style: TextStyle(
              color: _statusColor(record),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          width: 96,
          child: switch (action) {
            null => const SizedBox.shrink(),
            final action => TextButton(
              onPressed: action.onTap,
              child: Text('${action.label} →'),
            ),
          },
        ),
      ],
    ),
  );
}

class _MobileAttendanceCard extends StatelessWidget {
  const _MobileAttendanceCard({required this.record, this.action});
  final AttendanceRecord record;
  final _RecordAction? action;

  @override
  Widget build(BuildContext context) => AdminSurface(
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          record.className,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          '${formatBrDateTime(record.date)} · '
          '${record.present} de ${record.total} presentes',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                _statusLabel(record),
                style: TextStyle(
                  color: _statusColor(record),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            if (action case final action?)
              TextButton(onPressed: action.onTap, child: Text(action.label)),
          ],
        ),
      ],
    ),
  );
}

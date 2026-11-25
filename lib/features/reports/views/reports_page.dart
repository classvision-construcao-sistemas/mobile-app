import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';

/// Indicadores de presença calculados a partir do histórico de chamadas.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<SchoolRepository?>();
    final report = _Report(
      classes: repository?.classes ?? const [],
      history: repository?.history ?? const [],
      rateOf: repository?.attendanceRateOf ?? (_) => null,
      now: DateTime.now(),
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 900
          ? _DesktopReports(report: report)
          : _MobileReports(report: report),
    );
  }
}

class _Report {
  _Report({
    required this.classes,
    required this.history,
    required this.rateOf,
    required this.now,
  });

  /// Meta de presença usada para destacar alunos e turmas em atenção.
  static const goal = .85;

  final List<SchoolClass> classes;
  final List<AttendanceRecord> history;
  final double? Function(String registration) rateOf;
  final DateTime now;

  late final double? overall = _rate(history);

  late final int studentsBelowGoal = {
    for (final classroom in classes)
      for (final student in classroom.students)
        if ((rateOf(student.registration) ?? 1) < goal) student.registration,
  }.length;

  late final int corrected = history
      .where((it) => it.status == AttendanceRecord.corrected)
      .length;

  /// Presença das últimas 4 semanas (da mais antiga para a atual).
  late final List<double?> weeks = [
    for (var week = 3; week >= 0; week--)
      _rate([
        for (final record in history)
          if (_weekIndex(record.date) == week) record,
      ]),
  ];

  /// Turmas com chamadas, da menor para a maior presença.
  late final List<(String, double)> byClass = [
    for (final classroom in classes)
      if (_rate([
            for (final record in history)
              if (record.classId == classroom.id) record,
          ])
          case final rate?)
        (classroom.name, rate),
  ]..sort((a, b) => a.$2.compareTo(b.$2));

  late final List<(String, double)> byCourse = () {
    final groups = <String, List<AttendanceRecord>>{};
    for (final record in history) {
      final classroom = classes
          .where((it) => it.id == record.classId)
          .firstOrNull;
      final course = classroom?.courseName ?? '';
      groups
          .putIfAbsent(course.isEmpty ? 'Sem curso' : course, () => [])
          .add(record);
    }
    return [
      for (final entry in groups.entries)
        if (_rate(entry.value) case final rate?) (entry.key, rate),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
  }();

  String get periodLabel {
    if (history.isEmpty) return 'Nenhuma chamada registrada';
    final first = history
        .map((it) => it.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final last = history
        .map((it) => it.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return 'Indicadores de ${_date(first)} a ${_date(last)}';
  }

  int _weekIndex(DateTime date) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    if (!day.isBefore(startOfWeek)) return 0;
    return (startOfWeek.difference(day).inDays - 1) ~/ 7 + 1;
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  static double? _rate(List<AttendanceRecord> records) {
    final total = records.fold<int>(0, (sum, it) => sum + it.total);
    if (total == 0) return null;
    return records.fold<int>(0, (sum, it) => sum + it.present) / total;
  }
}

String _percent(double? rate) => rate == null
    ? '—'
    : '${(rate * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

class _DesktopReports extends StatelessWidget {
  const _DesktopReports({required this.report});
  final _Report report;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
    children: [
      const Text(
        'Gestão acadêmica / Indicadores',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
      Row(
        children: [
          Expanded(
            child: MetricCard(
              label: 'PRESENÇA GERAL',
              value: _percent(report.overall),
              supportingText: report.periodLabel,
              valueColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: MetricCard(
              label: 'ALUNOS EM ATENÇÃO',
              value: '${report.studentsBelowGoal}',
              supportingText: 'abaixo de 85% de presença',
              valueColor: AppColors.warning,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: MetricCard(
              label: 'CHAMADAS REALIZADAS',
              value: '${report.history.length}',
              supportingText: 'em ${report.classes.length} turma(s)',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: MetricCard(
              label: 'CHAMADAS CORRIGIDAS',
              value: '${report.corrected}',
              supportingText: 'com justificativa',
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _Chart(title: 'Evolução da presença', weeks: report.weeks),
          ),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: _AttentionList(byClass: report.byClass)),
        ],
      ),
      const SizedBox(height: 22),
      _Comparison(byCourse: report.byCourse, overall: report.overall),
    ],
  );
}

class _MobileReports extends StatelessWidget {
  const _MobileReports({required this.report});
  final _Report report;

  @override
  Widget build(BuildContext context) {
    final attention = report.byClass
        .where((it) => it.$2 < _Report.goal)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text(
          'Relatórios',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          report.periodLabel,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 20),
        MetricCard(
          label: 'PRESENÇA GERAL',
          value: _percent(report.overall),
          supportingText: '${report.history.length} chamada(s)',
          valueColor: AppColors.primary,
        ),
        const SizedBox(height: 16),
        _Chart(title: 'Evolução semanal', weeks: report.weeks),
        const SizedBox(height: 16),
        const Text(
          'Turmas em atenção',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (attention.isEmpty)
          const AdminSurface(
            child: Text(
              'Nenhuma turma abaixo da meta de presença.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        for (final (name, rate) in attention) ...[
          AdminSurface(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Abaixo da meta de presença',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _percent(rate),
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.title, required this.weeks});
  final String title;
  final List<double?> weeks;

  static const _labels = ['-3 sem.', '-2 sem.', '-1 sem.', 'Atual'];

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
              for (var index = 0; index < weeks.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Tooltip(
                      message: _percent(weeks[index]),
                      child: Container(
                        height: weeks[index] == null
                            ? 4
                            : 4 + weeks[index]! * 100,
                        decoration: BoxDecoration(
                          color: index == weeks.length - 1
                              ? AppColors.primary
                              : AppColors.primarySoft,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final label in _labels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _AttentionList extends StatelessWidget {
  const _AttentionList({required this.byClass});
  final List<(String, double)> byClass;

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Turmas com menor presença',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        if (byClass.isEmpty)
          const Text(
            'Sem chamadas registradas.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        for (final (name, rate) in byClass.take(3))
          ListTile(title: Text(name), trailing: Text(_percent(rate))),
      ],
    ),
  );
}

class _Comparison extends StatelessWidget {
  const _Comparison({required this.byCourse, required this.overall});
  final List<(String, double)> byCourse;
  final double? overall;

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comparativo por curso',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final (course, rate) in byCourse.take(3))
              Expanded(
                child: Text(
                  '$course\n${_percent(rate)}',
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: Text(
                'Média institucional\n${_percent(overall)}',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

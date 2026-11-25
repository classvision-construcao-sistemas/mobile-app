import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../core/widgets/classvision_logo.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/school_repository.dart';
import 'getting_started_card.dart';

/// Painel inicial da área acadêmica, montado com as turmas do turma-service
/// e o histórico de chamadas do auditoria-service.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onOpenCamera,
    this.userName = 'Lucas',
    this.onOpenReview,
    this.onOpenNotifications,
    this.onViewAllPending,
    this.onOpenCameraFor,
  });

  final VoidCallback onOpenCamera;
  final String userName;
  final VoidCallback? onOpenReview;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onViewAllPending;

  /// Abre a câmera já com a turma escolhida.
  final ValueChanged<String>? onOpenCameraFor;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<SchoolRepository?>();
    final auth = context.watch<AuthRepository?>();
    final summary = _HomeSummary(
      classes: repository?.classes ?? const [],
      history: repository?.history ?? const [],
      institutionName: auth?.institution?.name,
      now: DateTime.now(),
    );
    void startAttendance(String classId) =>
        onOpenCameraFor != null ? onOpenCameraFor!(classId) : onOpenCamera();

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 900
          ? _DesktopDashboard(
              userName: userName,
              summary: summary,
              onOpenCamera: onOpenCamera,
              onStartAttendance: startAttendance,
              onOpenNotifications: onOpenNotifications,
              onViewAllPending: onViewAllPending,
            )
          : _MobileDashboard(
              userName: userName,
              summary: summary,
              onStartAttendance: startAttendance,
            ),
    );
  }
}

/// Indicadores calculados a partir dos dados carregados.
class _HomeSummary {
  _HomeSummary({
    required this.classes,
    required this.history,
    required this.institutionName,
    required this.now,
  });

  final List<SchoolClass> classes;
  final List<AttendanceRecord> history;
  final String? institutionName;
  final DateTime now;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  late final List<AttendanceRecord> today = [
    for (final record in history)
      if (_sameDay(record.date, now)) record,
  ];

  /// Presença média de todas as chamadas registradas (null sem chamadas).
  late final double? averagePresence = _rate(history);

  late final int activeStudents = {
    for (final classroom in classes)
      for (final student in classroom.students)
        if (_active(student)) student.registration,
  }.length;

  /// Turmas sem chamada registrada hoje.
  late final List<SchoolClass> pending = [
    for (final classroom in classes)
      if (classroom.isRemote &&
          !classroom.attendanceCompleted &&
          !today.any((record) => record.classId == classroom.id))
        classroom,
  ];

  /// Presença média por dia da semana atual (segunda a sábado).
  late final List<double?> week = () {
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return [
      for (var day = 0; day < 6; day++)
        _rate([
          for (final record in history)
            if (_sameDay(record.date, monday.add(Duration(days: day)))) record,
        ]),
    ];
  }();

  double? rateFor(SchoolClass classroom) => _rate([
    for (final record in history)
      if (record.classId == classroom.id) record,
  ]);

  static bool _active(Student student) {
    final status = student.enrollmentStatus?.toUpperCase();
    return status == null || status == 'ATIVO' || status == 'MATRICULADO';
  }

  static double? _rate(List<AttendanceRecord> records) {
    final total = records.fold<int>(0, (sum, it) => sum + it.total);
    if (total == 0) return null;
    return records.fold<int>(0, (sum, it) => sum + it.present) / total;
  }
}

String _percent(double? rate) => rate == null
    ? '—'
    : '${(rate * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

const _weekdays = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];
const _months = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// "Bom dia", "Boa tarde" ou "Boa noite" conforme a hora, com o nome.
String homeGreeting(String name, [DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  final greeting = hour < 5
      ? 'Boa noite'
      : hour < 12
      ? 'Bom dia'
      : hour < 18
      ? 'Boa tarde'
      : 'Boa noite';
  return name.isEmpty ? greeting : '$greeting, $name';
}

String _longDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${date.day} de ${_months[date.month - 1]}';

String _shortDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1].substring(0, 3)}. ${date.year}';

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((it) => it.isNotEmpty);
  final initials = parts.take(2).map((it) => it[0].toUpperCase()).join();
  return initials.isEmpty ? '?' : initials;
}

String _classInitials(String name) {
  final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ ]'), ' ');
  return _initials(cleaned);
}

String _relative(DateTime date, DateTime now) {
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  return 'há ${diff.inDays} d';
}

class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({
    required this.userName,
    required this.summary,
    required this.onOpenCamera,
    required this.onStartAttendance,
    this.onOpenNotifications,
    this.onViewAllPending,
  });
  final String userName;
  final _HomeSummary summary;
  final VoidCallback onOpenCamera;
  final ValueChanged<String> onStartAttendance;
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
                  homeGreeting(userName, summary.now),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  summary.institutionName == null
                      ? 'Acompanhe a presença das suas turmas.'
                      : 'Acompanhe a presença do ${summary.institutionName}.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onOpenCamera,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Fazer chamada'),
          ),
          const SizedBox(width: 14),
          IconButton.filledTonal(
            onPressed: onOpenNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primary,
            child: Text(_initials(userName)),
          ),
        ],
      ),
      const SizedBox(height: 26),
      GettingStartedCard(onStartAttendance: onStartAttendance),
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
            child: Text(
              _shortDate(summary.now),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: MetricCard(
              label: 'Presença média',
              value: _percent(summary.averagePresence),
              supportingText:
                  '${summary.history.length} chamada(s) no histórico',
              valueColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              label: 'Chamadas realizadas',
              value: '${summary.today.length}',
              supportingText: 'hoje, em ${summary.classes.length} turma(s)',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              label: 'Alunos ativos',
              value: '${summary.activeStudents}',
              supportingText: 'em ${summary.classes.length} turma(s)',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              label: 'Pendências',
              value: '${summary.pending.length}',
              supportingText: 'turmas sem chamada hoje',
              valueColor: AppColors.warning,
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _PresenceChart(week: summary.week)),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: _ReviewPanel(
              pending: summary.pending,
              onStartAttendance: onStartAttendance,
              onViewAllPending: onViewAllPending,
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      _RecentActivity(history: summary.history, now: summary.now),
    ],
  );
}

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({
    required this.userName,
    required this.summary,
    required this.onStartAttendance,
  });
  final String userName;
  final _HomeSummary summary;
  final ValueChanged<String> onStartAttendance;

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('home-mobile'),
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: ClassVisionLogo(size: 28),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homeGreeting(userName, summary.now),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _longDate(summary.now),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primary,
            child: Text(
              _initials(userName),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      GettingStartedCard(onStartAttendance: onStartAttendance),
      const Text(
        'Resumo de hoje',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      AdminSurface(
        child: Row(
          children: [
            Expanded(
              child: _MobileMetric(
                label: 'PRESENÇA MÉDIA',
                value: _percent(summary.averagePresence),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: _MobileMetric(
                label: 'PENDÊNCIAS',
                value: '${summary.pending.length}',
                color: AppColors.warning,
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
      if (summary.pending.isEmpty)
        const AdminSurface(
          child: Text(
            'Todas as turmas já têm chamada hoje.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        )
      else
        for (final classroom in summary.pending.take(3)) ...[
          _MobileReviewCard(
            title: classroom.courseName.isEmpty
                ? classroom.name
                : '${classroom.name} · ${classroom.courseName}',
            subtitle: 'Chamada de hoje ainda não registrada',
            action: 'Fazer chamada',
            onTap: () => onStartAttendance(classroom.id),
          ),
          const SizedBox(height: 10),
        ],
      const SizedBox(height: 14),
      const Text(
        'Turmas em andamento',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 11),
      if (summary.classes.isEmpty)
        const AdminSurface(
          child: Text(
            'Nenhuma turma cadastrada.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        )
      else
        for (final classroom in summary.classes.take(3)) ...[
          AdminSurface(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  child: Text(
                    _classInitials(classroom.name),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroom.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          '${classroom.students.length} aluno(s)',
                          if (classroom.room.isNotEmpty) classroom.room,
                        ].join(' · '),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _percent(summary.rateFor(classroom)),
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _MobileMetric extends StatelessWidget {
  const _MobileMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        value,
        style: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    ],
  );
}

class _PresenceChart extends StatelessWidget {
  const _PresenceChart({required this.week});
  final List<double?> week;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday - 1;
    return AdminSurface(
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
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var day = 0; day < week.length; day++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      child: Tooltip(
                        message: _percent(week[day]),
                        child: Container(
                          height: week[day] == null ? 4 : 4 + week[day]! * 116,
                          decoration: BoxDecoration(
                            color: day == today
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
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.pending,
    required this.onStartAttendance,
    this.onViewAllPending,
  });
  final List<SchoolClass> pending;
  final ValueChanged<String> onStartAttendance;
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
        Text(
          pending.isEmpty
              ? 'Todas as turmas já têm chamada hoje'
              : '${pending.length} turma(s) sem chamada hoje',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),
        for (final (index, classroom) in pending.take(4).indexed) ...[
          if (index > 0) const Divider(),
          _DesktopReviewRow(
            title: classroom.courseName.isEmpty
                ? classroom.name
                : '${classroom.name} — ${classroom.courseName}',
            subtitle:
                '${classroom.students.length} aluno(s) · '
                'chamada não registrada',
            onTap: () => onStartAttendance(classroom.id),
          ),
        ],
        TextButton(
          onPressed: onViewAllPending,
          child: const Text('Ver histórico de chamadas →'),
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
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      TextButton(onPressed: onTap, child: const Text('Fazer chamada')),
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
                  fontSize: 12,
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
  const _RecentActivity({required this.history, required this.now});
  final List<AttendanceRecord> history;
  final DateTime now;

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
          'Últimas chamadas registradas',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),
        if (history.isEmpty)
          const Text(
            'Nenhuma chamada registrada ainda.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        for (final record in history.take(4))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.primarySoft,
              child: Icon(
                record.status == AttendanceRecord.corrected
                    ? Icons.edit_note_rounded
                    : Icons.check_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            title: Text(
              '${record.status == AttendanceRecord.corrected ? 'Chamada corrigida' : 'Chamada confirmada'}'
              ' — ${record.className}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            subtitle: Text(
              '${record.present} de ${record.total} presentes',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              _relative(record.date, now),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    ),
  );
}

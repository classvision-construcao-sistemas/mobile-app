import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';

/// Alunos vinculados às turmas (turma-service), com os dados do cadastro
/// facial e a frequência calculada a partir do histórico de chamadas.
class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentRow {
  const _StudentRow({
    required this.student,
    required this.classroom,
    required this.rate,
  });
  final Student student;
  final SchoolClass classroom;
  final double? rate;

  bool get active {
    final status = student.enrollmentStatus?.toUpperCase();
    return status == null || status == 'ATIVO' || status == 'MATRICULADO';
  }

  String get status {
    if (!active) return _capitalize(student.enrollmentStatus!);
    final value = rate;
    if (value == null) return 'Sem chamadas';
    if (value >= .85) return 'Ativo';
    if (value >= .75) return 'Atenção';
    return 'Crítico';
  }

  Color get statusColor => switch (status) {
    'Ativo' => const Color(0xFF15803D),
    'Atenção' => AppColors.warning,
    'Crítico' => AppColors.error,
    _ => AppColors.textSecondary,
  };

  static String _capitalize(String value) => value.isEmpty
      ? value
      : value[0].toUpperCase() + value.substring(1).toLowerCase();
}

class _StudentsPageState extends State<StudentsPage> {
  final _search = TextEditingController();
  String? _classId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _percent(double? rate) => rate == null
      ? '—'
      : '${(rate * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

  void _newStudent(SchoolRepository repository) {
    final classroom =
        repository.findClassById(_classId) ??
        repository.classes.where((it) => it.isRemote).firstOrNull ??
        repository.classes.firstOrNull;
    if (classroom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre uma turma primeiro.')),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.studentRegistration,
      arguments: classroom.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<SchoolRepository>();
    final query = _search.text.trim().toLowerCase();
    final classes = repository.classes.where((it) => it.isRemote).toList();
    final rows = [
      for (final classroom in classes)
        if (_classId == null || classroom.id == _classId)
          for (final student in classroom.students)
            if (query.isEmpty ||
                student.name.toLowerCase().contains(query) ||
                student.registration.contains(query))
              _StudentRow(
                student: student,
                classroom: classroom,
                rate: repository.attendanceRateOf(student.registration),
              ),
    ]..sort((a, b) => a.student.name.compareTo(b.student.name));
    final activeCount = rows.where((row) => row.active).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestão acadêmica / Pessoas',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 9),
                  Text(
                    'Alunos',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Consulte registros, presença e informações de matrícula.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (repository.canManageEnrollments)
              FilledButton.icon(
                onPressed: () => _newStudent(repository),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Novo aluno'),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AppSearchField(
                controller: _search,
                hint: 'Buscar por nome ou matrícula',
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            AppFilterDropdown<String?>(
              value: classes.any((it) => it.id == _classId) ? _classId : null,
              options: [
                (null, 'Todas as turmas'),
                for (final classroom in classes) (classroom.id, classroom.name),
              ],
              onChanged: (value) => setState(() => _classId = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '$activeCount aluno(s) ativo(s)',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        AdminSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('ALUNO')),
                    Expanded(child: Text('MATRÍCULA')),
                    Expanded(child: Text('TURMA')),
                    Expanded(child: Text('PRESENÇA')),
                    Expanded(child: Text('STATUS')),
                  ],
                ),
              ),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    repository.loading
                        ? 'Carregando alunos...'
                        : 'Nenhum aluno vinculado às turmas.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              for (final row in rows)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primarySoft,
                              child: Text(
                                row.student.initials.isEmpty
                                    ? '?'
                                    : row.student.initials,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row.student.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (row.student.guardian.isNotEmpty)
                                    Text(
                                      'Responsável: ${row.student.guardian}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: Text(row.student.registration)),
                      Expanded(child: Text(row.classroom.name)),
                      Expanded(child: Text(_percent(row.rate))),
                      Expanded(
                        child: Text(
                          row.status,
                          style: TextStyle(
                            color: row.statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

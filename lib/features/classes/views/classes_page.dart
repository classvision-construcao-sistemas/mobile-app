import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key, this.onOpenClass});
  final ValueChanged<String>? onOpenClass;

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<SchoolRepository>().classes;
    final rows = [
      for (var index = 0; index < classes.length; index++)
        _ClassRowData.fromClass(classes[index], index),
    ];
    void open(String id) => onOpenClass != null
        ? onOpenClass!(id)
        : Navigator.pushNamed(context, AppRoutes.classDetails, arguments: id);
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 900
          ? _DesktopClasses(rows: rows, onOpenClass: open)
          : _MobileClasses(rows: rows, onOpenClass: open),
    );
  }
}

class _DesktopClasses extends StatelessWidget {
  const _DesktopClasses({required this.rows, required this.onOpenClass});
  final List<_ClassRowData> rows;
  final ValueChanged<String> onOpenClass;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instituto Federal Goiano  /  Gestão acadêmica',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Turmas',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 5),
                Text(
                  'Gerencie as turmas, docentes e o acompanhamento de presença.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.classRegistration),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nova turma'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      AdminSurface(
        child: Row(
          children: [
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar por turma ou professor',
                ),
              ),
            ),
            const SizedBox(width: 12),
            _Filter(label: 'Todos os cursos'),
            const SizedBox(width: 10),
            _Filter(label: '2026/2'),
            const SizedBox(width: 10),
            const Text(
              'Filtros avançados',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const Row(
        children: [
          Expanded(
            child: Text(
              '28 turmas cadastradas',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            'Semestre 2026/2 · Atualizado hoje às 09:42',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
      const SizedBox(height: 12),
      AdminSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const _ClassTableHeader(),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Text('Nenhuma turma cadastrada nesta sessão.'),
              )
            else
              for (final item in rows)
                _ClassTableRow(
                  item: item,
                  onTap: () => onOpenClass(item.classroom.id),
                ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Row(
        children: [
          Expanded(
            child: Text(
              'Mostrando 1–5 de 28 turmas',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          Text('‹    1    2    ›'),
        ],
      ),
    ],
  );
}

class _MobileClasses extends StatelessWidget {
  const _MobileClasses({required this.rows, required this.onOpenClass});
  final List<_ClassRowData> rows;
  final ValueChanged<String> onOpenClass;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
    children: [
      const Text(
        'Turmas',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      const Text(
        '28 turmas no semestre 2026/2',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      const SizedBox(height: 18),
      const TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded),
          hintText: 'Buscar turma',
        ),
      ),
      const SizedBox(height: 16),
      if (rows.isEmpty)
        const AdminSurface(
          child: Center(child: Text('Nenhuma turma cadastrada nesta sessão.')),
        )
      else
        for (final item in rows.take(5)) ...[
          InkWell(
            onTap: () => onOpenClass(item.classroom.id),
            borderRadius: BorderRadius.circular(16),
            child: AdminSurface(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primary,
                    child: Text(
                      item.initials,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.classroom.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.course} · ${item.classroom.students.length} alunos',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.presence,
                    style: TextStyle(
                      color: item.status == 'Atenção'
                          ? AppColors.warning
                          : const Color(0xFF15803D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      const SizedBox(height: 14),
      const Text(
        'Filtros rápidos',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      const Wrap(
        spacing: 8,
        children: [
          Chip(label: Text('Todas')),
          Chip(label: Text('Em atenção')),
          Chip(label: Text('Ativas')),
        ],
      ),
    ],
  );
}

class _Filter extends StatelessWidget {
  const _Filter({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 6),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 15),
      ],
    ),
  );
}

class _ClassTableHeader extends StatelessWidget {
  const _ClassTableHeader();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    child: Row(
      children: [
        Expanded(flex: 3, child: Text('TURMA')),
        Expanded(flex: 2, child: Text('PROFESSOR RESPONSÁVEL')),
        Expanded(child: Text('ALUNOS')),
        Expanded(child: Text('PRESENÇA')),
        Expanded(child: Text('STATUS')),
      ],
    ),
  );
}

class _ClassTableRow extends StatelessWidget {
  const _ClassTableRow({required this.item, required this.onTap});
  final _ClassRowData item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
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
                  child: Text(item.initials),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.classroom.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${item.course} · ${item.classroom.room}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(item.teacher)),
          Expanded(child: Text('${item.classroom.students.length}')),
          Expanded(
            child: Text(
              item.presence,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              item.status,
              style: TextStyle(
                color: item.status == 'Atenção'
                    ? AppColors.warning
                    : const Color(0xFF15803D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ClassRowData {
  const _ClassRowData({
    required this.classroom,
    required this.initials,
    required this.course,
    required this.teacher,
    required this.presence,
    required this.status,
  });

  final SchoolClass classroom;
  final String initials;
  final String course;
  final String teacher;
  final String presence;
  final String status;

  factory _ClassRowData.fromClass(SchoolClass classroom, int index) {
    const metadata = [
      ('Informática', 'Rafael Mendes', '96,8%', 'Ativa'),
      ('Agropecuária', 'Camila Ribeiro', '95,3%', 'Ativa'),
      ('Química', 'João Vitor Lima', '82,1%', 'Atenção'),
      ('Informática', 'Ana Paula Rocha', '94,7%', 'Ativa'),
      ('Alimentos', 'Fernanda Alves', '93,9%', 'Ativa'),
    ];
    final meta = index < metadata.length
        ? metadata[index]
        : const (
            'Curso não informado',
            'Professor não atribuído',
            '—',
            'Ativa',
          );
    final words = classroom.name.split(' ');
    final initials = words.length >= 2
        ? '${words.first.replaceAll(RegExp(r'\D'), '')}${words.last[0]}'
              .toUpperCase()
        : classroom.name
              .substring(0, classroom.name.length.clamp(0, 2))
              .toUpperCase();
    return _ClassRowData(
      classroom: classroom,
      initials: initials.isEmpty ? 'T' : initials,
      course: meta.$1,
      teacher: meta.$2,
      presence: meta.$3,
      status: meta.$4,
    );
  }
}

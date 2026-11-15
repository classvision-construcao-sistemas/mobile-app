import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  static const classes = [
    (
      '2A',
      '2º Ano A',
      'Informática · 32 alunos',
      'Rafael Mendes',
      '96,8%',
      'Ativa',
    ),
    (
      '1C',
      '1º Ano C',
      'Agropecuária · 31 alunos',
      'Camila Ribeiro',
      '95,3%',
      'Ativa',
    ),
    (
      '3B',
      '3º Ano B',
      'Química · 29 alunos',
      'João Vitor Lima',
      '82,1%',
      'Atenção',
    ),
    (
      '2D',
      '2º Ano D',
      'Informática · 34 alunos',
      'Ana Paula Rocha',
      '94,7%',
      'Ativa',
    ),
    (
      '1B',
      '1º Ano B',
      'Alimentos · 30 alunos',
      'Fernanda Alves',
      '93,9%',
      'Ativa',
    ),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 900
        ? const _DesktopClasses()
        : const _MobileClasses(),
  );
}

class _DesktopClasses extends StatelessWidget {
  const _DesktopClasses();
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
            onPressed: () {},
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
            for (final item in ClassesPage.classes) _ClassTableRow(item: item),
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
  const _MobileClasses();
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
      for (final item in ClassesPage.classes.take(3)) ...[
        AdminSurface(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primary,
                child: Text(
                  item.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$3,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item.$5,
                style: TextStyle(
                  color: item.$6 == 'Atenção'
                      ? AppColors.warning
                      : const Color(0xFF15803D),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
  const _ClassTableRow({required this.item});
  final (String, String, String, String, String, String) item;
  @override
  Widget build(BuildContext context) => Container(
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
                child: Text(item.$1),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$2,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    item.$3,
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
        Expanded(flex: 2, child: Text(item.$4)),
        const Expanded(child: Text('32')),
        Expanded(
          child: Text(
            item.$5,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(
            item.$6,
            style: TextStyle(
              color: item.$6 == 'Atenção'
                  ? AppColors.warning
                  : const Color(0xFF15803D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

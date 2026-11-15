import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});
  static const students = [
    (
      'AB',
      'Ana Beatriz Rocha',
      'ana.rocha@ifgo.edu.br',
      '20260231',
      '2º Ano A',
      '98,1%',
      'Ativo',
    ),
    (
      'BN',
      'Beatriz Nogueira',
      'beatriz.n@ifgo.edu.br',
      '20260242',
      '2º Ano A',
      '81,5%',
      'Atenção',
    ),
    (
      'CM',
      'Caio Moreira',
      'caio.m@ifgo.edu.br',
      '20260118',
      '1º Ano C',
      '96,7%',
      'Ativo',
    ),
    (
      'LM',
      'Lucas Martins',
      'lucas.m@ifgo.edu.br',
      '20260256',
      '2º Ano A',
      '77,8%',
      'Crítico',
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
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
                    fontSize: 11,
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
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: const Text('Novo aluno'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      const AdminSurface(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar por nome ou matrícula',
                ),
              ),
            ),
            SizedBox(width: 14),
            Text('Todas as turmas  ⌄'),
            SizedBox(width: 20),
            Text('Status ativo  ⌄'),
            SizedBox(width: 20),
            Text(
              'Exportar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        '742 alunos ativos',
        style: TextStyle(fontWeight: FontWeight.w800),
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
            for (final item in students)
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
                            child: Text(item.$1),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$2,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
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
                    Expanded(child: Text(item.$4)),
                    Expanded(child: Text(item.$5)),
                    Expanded(child: Text(item.$6)),
                    Expanded(
                      child: Text(
                        item.$7,
                        style: TextStyle(
                          color: item.$7 == 'Ativo'
                              ? const Color(0xFF15803D)
                              : AppColors.warning,
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

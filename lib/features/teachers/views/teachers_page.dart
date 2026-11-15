import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';

class TeachersPage extends StatelessWidget {
  const TeachersPage({super.key});
  static const teachers = [
    (
      'RM',
      'Rafael Mendes',
      'Matemática',
      '2º Ano A, 1º Ano B',
      '96,8%',
      'Ativo',
    ),
    ('CR', 'Camila Ribeiro', 'Biologia', '1º Ano C', '95,3%', 'Ativo'),
    ('JV', 'João Vitor Lima', 'Química', '3º Ano B', '82,1%', 'Atenção'),
    ('AR', 'Ana Paula Rocha', 'Programação', '2º Ano D', '94,7%', 'Ativo'),
  ];

  Future<void> _invite(BuildContext context) async {
    final controller = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Convidar professor'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail institucional',
            hintText: 'professor@instituicao.edu.br',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.contains('@') && controller.text.contains('.'),
            ),
            child: const Text('Enviar convite'),
          ),
        ],
      ),
    );
    if (sent != true || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Convite enviado.')));
  }

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
                  'Professores',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 5),
                Text(
                  'Acompanhe docentes, turmas atribuídas e convites pendentes.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _invite(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Convidar professor'),
          ),
        ],
      ),
      const SizedBox(height: 22),
      const Row(
        children: [
          Expanded(
            child: MetricCard(label: 'ATIVOS', value: '18'),
          ),
          SizedBox(width: 16),
          Expanded(
            child: MetricCard(label: 'TURMAS ATRIBUÍDAS', value: '28'),
          ),
          SizedBox(width: 16),
          Expanded(
            child: MetricCard(
              label: 'CONVITES PENDENTES',
              value: '2',
              valueColor: AppColors.warning,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded),
          hintText: 'Buscar professor',
        ),
      ),
      const SizedBox(height: 14),
      AdminSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final item in teachers)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: Text(item.$1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.$2,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(child: Text(item.$3)),
                    Expanded(flex: 2, child: Text(item.$4)),
                    Expanded(child: Text(item.$5)),
                    Text(
                      item.$6,
                      style: TextStyle(
                        color: item.$6 == 'Ativo'
                            ? const Color(0xFF15803D)
                            : AppColors.warning,
                        fontWeight: FontWeight.w700,
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

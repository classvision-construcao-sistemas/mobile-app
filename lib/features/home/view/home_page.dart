import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/repositories/mock_school_repository.dart';
import '../../classes/widgets/school_class_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onOpenCamera});

  final VoidCallback onOpenCamera;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<MockSchoolRepository>();
    final firstName = repository.profile.name.split(' ').first;
    final classes = repository.classes.take(2);
    final date = _formatDate(DateTime.now());

    return ListView(
      key: const PageStorageKey('home'),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      children: [
        AppPageTitle(
          'Bom dia, $firstName',
          subtitle: '${date[0].toUpperCase()}${date.substring(1)}',
          trailing: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              repository.profile.name
                  .split(' ')
                  .take(2)
                  .map((part) => part[0])
                  .join(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'Fazer chamada com IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fotografe a sala e confira os alunos reconhecidos.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .86),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onOpenCamera,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Abrir câmera'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.face_retouching_natural,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Próximas turmas',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        for (final classroom in classes) ...[
          SchoolClassCard(
            classroom: classroom,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.classDetails,
              arguments: classroom.id,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

String _formatDate(DateTime date) {
  const weekdays = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
  const months = [
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
  return '${weekdays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
}

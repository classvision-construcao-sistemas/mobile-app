import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../domain/admin_models.dart';

class InstitutionCreatedPage extends StatelessWidget {
  const InstitutionCreatedPage({
    super.key,
    required this.institution,
    required this.adminName,
    required this.adminEmail,
    required this.onViewInstitution,
    required this.onBackToList,
  });
  final Institution institution;
  final String adminName;
  final String adminEmail;
  final VoidCallback onViewInstitution;
  final VoidCallback onBackToList;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: AdminSurface(
          padding: const EdgeInsets.all(42),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF15803D),
                  size: 38,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Instituição cadastrada!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                '${institution.name} já está disponível na plataforma.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONVITE ENVIADO PARA',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      adminName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adminEmail,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onViewInstitution,
                  child: const Text('Ver instituição'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onBackToList,
                child: const Text('Voltar para instituições'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

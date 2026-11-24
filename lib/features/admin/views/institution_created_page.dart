import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../domain/admin_models.dart';

class InstitutionCreatedPage extends StatelessWidget {
  const InstitutionCreatedPage({
    super.key,
    required this.institution,
    required this.onRegisterAdmin,
    required this.onViewInstitution,
    required this.onBackToList,
  });
  final Institution institution;

  /// Abre o cadastro do administrador da instituição (um usuário).
  final VoidCallback onRegisterAdmin;
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
                      'PRÓXIMO PASSO',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Cadastre o administrador da instituição. Ele recebe '
                      'e-mail e senha de acesso e cadastra coordenadores, '
                      'professores e secretários.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRegisterAdmin,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Cadastrar administrador'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
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

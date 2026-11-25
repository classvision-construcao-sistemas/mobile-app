import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../data/repositories/school_repository.dart';

/// Passo a passo do primeiro acesso: criar a turma, cadastrar os alunos com
/// foto e fazer a primeira chamada. Some quando os três estão feitos.
class GettingStartedCard extends StatelessWidget {
  const GettingStartedCard({super.key, required this.onStartAttendance});

  final ValueChanged<String> onStartAttendance;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<SchoolRepository?>();
    if (repository == null || !repository.loaded) {
      return const SizedBox.shrink();
    }
    final classes = repository.classes;
    final hasClass = classes.isNotEmpty;
    final withStudents = classes
        .where((it) => it.students.isNotEmpty)
        .firstOrNull;
    final hasAttendance = repository.history.isNotEmpty;
    if (hasClass && withStudents != null && hasAttendance) {
      return const SizedBox.shrink();
    }

    final steps = [
      _Step(
        title: 'Crie a primeira turma',
        description: 'O curso pode ser criado no próprio formulário da turma.',
        done: hasClass,
        action: repository.canManageClasses
            ? ('Criar turma', () => _push(context, AppRoutes.classRegistration))
            : null,
      ),
      _Step(
        title: 'Cadastre os alunos com foto',
        description:
            'A foto de rosto de cada aluno é o que a IA usa para reconhecê-lo.',
        done: withStudents != null,
        action: hasClass && repository.canManageEnrollments
            ? (
                'Cadastrar aluno',
                () => _push(
                  context,
                  AppRoutes.studentRegistration,
                  classes.first.id,
                ),
              )
            : null,
      ),
      _Step(
        title: 'Faça a primeira chamada',
        description: 'Tire uma foto da sala e confira a lista antes de salvar.',
        done: hasAttendance,
        action: withStudents != null
            ? ('Fazer chamada', () => onStartAttendance(withStudents.id))
            : null,
      ),
    ];
    final current = steps.indexWhere((step) => !step.done);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AdminSurface(
        key: const Key('getting-started'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Primeiros passos',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${steps.where((it) => it.done).length} de 3 concluídos',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < steps.length; index++)
              _StepTile(
                number: index + 1,
                step: steps[index],
                current: index == current,
              ),
          ],
        ),
      ),
    );
  }

  static Future<void> _push(
    BuildContext context,
    String route, [
    Object? arguments,
  ]) => Navigator.pushNamed(context, route, arguments: arguments);
}

class _Step {
  const _Step({
    required this.title,
    required this.description,
    required this.done,
    this.action,
  });

  final String title;
  final String description;
  final bool done;
  final (String, VoidCallback)? action;
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.step,
    required this.current,
  });

  final int number;
  final _Step step;
  final bool current;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: step.done
              ? AppColors.success
              : current
              ? AppColors.primary
              : AppColors.divider,
          foregroundColor: step.done || current
              ? Colors.white
              : AppColors.textSecondary,
          child: step.done
              ? const Icon(Icons.check_rounded, size: 18)
              : Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: step.done
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  decoration: step.done ? TextDecoration.lineThrough : null,
                ),
              ),
              if (!step.done) ...[
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              if (step.action case (final label, final onTap)? when current)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton(onPressed: onTap, child: Text(label)),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

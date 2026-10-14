import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/repositories/mock_school_repository.dart';
import '../viewmodels/classes_view_model.dart';
import '../widgets/school_class_card.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => ClassesViewModel(),
    child: const _ClassesContent(),
  );
}

class _ClassesContent extends StatelessWidget {
  const _ClassesContent();

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<MockSchoolRepository>();
    final viewModel = context.watch<ClassesViewModel>();
    final classes = viewModel.filter(repository.classes);

    return ListView(
      key: const PageStorageKey('classes'),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      children: [
        AppPageTitle(
          'Turmas',
          subtitle: 'Selecione uma turma para ver os alunos.',
          trailing: FilledButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.classRegistration),
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Nova turma'),
          ),
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Buscar',
          hint: 'Nome da turma ou sala',
          icon: Icons.search_rounded,
          onChanged: viewModel.search,
        ),
        const SizedBox(height: 16),
        if (classes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, size: 48),
                SizedBox(height: 12),
                Text('Nenhuma turma encontrada'),
              ],
            ),
          )
        else
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

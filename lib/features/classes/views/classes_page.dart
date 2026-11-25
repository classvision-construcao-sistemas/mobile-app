import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_cards.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/school_repository.dart';
import '../viewmodels/classes_view_model.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key, this.onOpenClass});
  final ValueChanged<String>? onOpenClass;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => ClassesViewModel(),
    child: _ClassesContent(onOpenClass: onOpenClass),
  );
}

class _ClassesContent extends StatefulWidget {
  const _ClassesContent({this.onOpenClass});
  final ValueChanged<String>? onOpenClass;

  @override
  State<_ClassesContent> createState() => _ClassesContentState();
}

class _ClassesContentState extends State<_ClassesContent> {
  @override
  void initState() {
    super.initState();
    final repository = context.read<SchoolRepository>();
    if (!repository.loaded && !repository.loading) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => repository.loadClasses(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<SchoolRepository>();
    final viewModel = context.watch<ClassesViewModel>();
    final remoteClasses = repository.classes
        .where((item) => item.isRemote)
        .toList();
    final rows = [
      for (final classroom in viewModel.filter(remoteClasses))
        _ClassRowData.fromClass(classroom),
    ];
    final state = _ListState(
      rows: rows,
      total: remoteClasses.length,
      loading: repository.loading,
      error: repository.error,
      canCreate: repository.canManageClasses,
      searching: viewModel.query.isNotEmpty,
      onRefresh: repository.loadClasses,
      onSearch: viewModel.search,
    );
    void open(String id) => widget.onOpenClass != null
        ? widget.onOpenClass!(id)
        : Navigator.pushNamed(context, AppRoutes.classDetails, arguments: id);
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 900
          ? _DesktopClasses(state: state, onOpenClass: open)
          : _MobileClasses(state: state, onOpenClass: open),
    );
  }
}

class _ListState {
  const _ListState({
    required this.rows,
    required this.total,
    required this.loading,
    required this.error,
    required this.canCreate,
    required this.searching,
    required this.onRefresh,
    required this.onSearch,
  });

  final List<_ClassRowData> rows;
  final int total;
  final bool loading;
  final String? error;
  final bool canCreate;
  final bool searching;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSearch;

  String get countLabel => switch (total) {
    0 => 'Nenhuma turma cadastrada',
    1 => '1 turma cadastrada',
    _ => '$total turmas cadastradas',
  };

  String get emptyMessage => searching
      ? 'Nenhuma turma encontrada para a busca.'
      : 'Nenhuma turma cadastrada no serviço de turmas.';
}

void _openRegistration(BuildContext context) =>
    Navigator.pushNamed(context, AppRoutes.classRegistration);

class _DesktopClasses extends StatelessWidget {
  const _DesktopClasses({required this.state, required this.onOpenClass});
  final _ListState state;
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
                  'Gestão acadêmica',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Turmas',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 5),
                Text(
                  'Gerencie as turmas, os cursos e o acompanhamento de presença.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: state.loading ? null : state.onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (state.canCreate) ...[
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _openRegistration(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova turma'),
            ),
          ],
        ],
      ),
      const SizedBox(height: 24),
      AppSearchField(
        hint: 'Buscar por turma, curso, sala ou turno',
        onChanged: state.onSearch,
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: Text(
              state.countLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (state.loading)
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (state.error != null) ...[
        AppErrorBanner(state.error!, onRetry: state.onRefresh),
        const SizedBox(height: 12),
      ],
      AdminSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const _ClassTableHeader(),
            if (state.rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(48),
                child: Text(
                  state.loading ? 'Carregando turmas...' : state.emptyMessage,
                ),
              )
            else
              for (final item in state.rows)
                _ClassTableRow(
                  item: item,
                  onTap: () => onOpenClass(item.classroom.id),
                ),
          ],
        ),
      ),
    ],
  );
}

class _MobileClasses extends StatelessWidget {
  const _MobileClasses({required this.state, required this.onOpenClass});
  final _ListState state;
  final ValueChanged<String> onOpenClass;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: state.onRefresh,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Turmas',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            if (state.canCreate)
              IconButton.filledTonal(
                tooltip: 'Nova turma',
                onPressed: () => _openRegistration(context),
                icon: const Icon(Icons.add_rounded),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          state.countLabel,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 18),
        AppSearchField(hint: 'Buscar turma', onChanged: state.onSearch),
        const SizedBox(height: 16),
        if (state.error != null) ...[
          AppErrorBanner(state.error!, onRetry: state.onRefresh),
          const SizedBox(height: 16),
        ],
        if (state.loading && state.rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.rows.isEmpty)
          AdminSurface(child: Center(child: Text(state.emptyMessage)))
        else
          for (final item in state.rows) ...[
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
                            '${item.course} · '
                            '${item.classroom.students.length} alunos',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.shift,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
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
        Expanded(flex: 2, child: Text('CURSO')),
        Expanded(child: Text('ANO')),
        Expanded(child: Text('TURNO')),
        Expanded(child: Text('ALUNOS')),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.classroom.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.classroom.room.isEmpty
                            ? 'Sala não informada'
                            : item.classroom.room,
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
          Expanded(
            flex: 2,
            child: Text(item.course, overflow: TextOverflow.ellipsis),
          ),
          Expanded(child: Text(item.year)),
          Expanded(
            child: Text(
              item.shift,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text('${item.classroom.students.length}')),
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
    required this.year,
    required this.shift,
  });

  final SchoolClass classroom;
  final String initials;
  final String course;
  final String year;
  final String shift;

  factory _ClassRowData.fromClass(SchoolClass classroom) {
    final words = classroom.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = switch (words.length) {
      0 => 'T',
      1 => words.first.substring(0, words.first.length.clamp(1, 2)),
      _ => '${words.first[0]}${words.last[0]}',
    }.toUpperCase();
    final year = classroom.remote?.year ?? 0;
    return _ClassRowData(
      classroom: classroom,
      initials: initials,
      course: classroom.courseName.isEmpty
          ? 'Curso não informado'
          : classroom.courseName,
      year: year == 0 ? '—' : '$year',
      shift: classroom.time.isEmpty ? '—' : classroom.time,
    );
  }
}

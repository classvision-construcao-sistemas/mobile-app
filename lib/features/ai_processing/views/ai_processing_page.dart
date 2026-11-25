import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/photo.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/repositories/school_repository.dart';
import '../../../data/services/facial_recognition_api.dart';
import '../../attendance/views/attendance_review_page.dart';
import '../../camera/views/camera_page.dart';
import '../view_models/ai_processing_view_model.dart';
import '../widgets/processing_orb.dart';
import '../widgets/processing_status_card.dart';

class AiProcessingPage extends StatefulWidget {
  const AiProcessingPage({super.key, required this.result, this.viewModel});

  final CameraResult result;
  final AiProcessingViewModel? viewModel;

  @override
  State<AiProcessingPage> createState() => _AiProcessingPageState();
}

class _AiProcessingPageState extends State<AiProcessingPage> {
  late final AiProcessingViewModel _viewModel;
  late final bool _ownsViewModel;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? _defaultViewModel();
    _viewModel.addListener(_onChanged);
    _viewModel.start();
  }

  /// Turmas do turma-service, com perfil autorizado, passam pelo
  /// auditoria-service (que só considera os alunos ativos da turma). As demais
  /// usam o reconhecimento facial direto.
  AiProcessingViewModel _defaultViewModel() {
    final repository = context.read<SchoolRepository>();
    final classId = widget.result.classId;
    final RoomAuditor auditor = repository.recordsAuditFor(classId)
        ? (path) => repository.previewAttendance(classId!, path)
        : context.read<FacialRecognitionApi>().auditRoom;
    return AiProcessingViewModel(
      imagePath: widget.result.imagePath,
      auditor: auditor,
    );
  }

  void _onChanged() {
    if (!_viewModel.state.isCompleted || !mounted || _navigating) return;
    final audit = _viewModel.result;
    if (audit == null) return;
    _navigating = true;

    final repository = context.read<SchoolRepository>();
    final classId = repository.prepareAuditClass(widget.result.classId);
    repository.applyFacialRecognition(classId, audit);

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.review,
      arguments: AttendanceReviewArgs(
        classId: classId,
        auditResult: audit,
        imagePath: widget.result.imagePath,
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 120,
                    width: 180,
                    child: photoPreview(
                      widget.result.imagePath,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: AppColors.primarySoft,
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -25),
                  child: const ProcessingOrb(),
                ),
                Text(
                  state.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: state.hasFailed
                        ? AppColors.error
                        : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                ProcessingStatusCard(steps: state.steps),
                if (state.hasFailed) ...[
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Tentar novamente',
                    icon: Icons.refresh_rounded,
                    onPressed: _viewModel.restart,
                  ),
                  const SizedBox(height: 9),
                  PrimaryButton(
                    label: 'Tirar nova foto',
                    outlined: true,
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.camera,
                      arguments: widget.result.classId,
                    ),
                  ),
                ],
                const Spacer(flex: 3),
              ],
            ),
          );
        },
      ),
    ),
  );
}

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel =
        widget.viewModel ??
        AiProcessingViewModel(stepDuration: const Duration(seconds: 1));
    _viewModel.addListener(_onChanged);
    _viewModel.start();
  }

  void _onChanged() {
    if (!_viewModel.state.isCompleted || !mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.review,
        arguments: widget.result.classId,
      );
    });
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
                    child: Image.file(
                      File(widget.result.imagePath),
                      fit: BoxFit.cover,
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
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                ProcessingStatusCard(steps: state.steps),
                const Spacer(flex: 3),
              ],
            ),
          );
        },
      ),
    ),
  );
}

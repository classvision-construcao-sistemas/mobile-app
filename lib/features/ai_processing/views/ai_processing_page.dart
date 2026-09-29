import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../view_models/ai_processing_view_model.dart';
import '../widgets/processing_orb.dart';
import '../widgets/processing_status_card.dart';

class AiProcessingPage extends StatefulWidget {
  const AiProcessingPage({super.key, this.viewModel});

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
    _viewModel = widget.viewModel ?? AiProcessingViewModel();
    _viewModel.start();
  }

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 390,
                height: 844,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: ColoredBox(
                    color: AppColors.background,
                    child: AnimatedBuilder(
                      animation: _viewModel,
                      builder: (context, _) {
                        final state = _viewModel.state;

                        return Stack(
                          children: [
                            const Positioned(
                              left: 143,
                              top: 193,
                              child: ProcessingOrb(),
                            ),
                            Positioned(
                              left: 24,
                              right: 24,
                              top: 314,
                              child: Transform.scale(
                                scaleX: .962,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    state.title,
                                    key: ValueKey(state.phase),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      height: 1,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 24,
                              right: 24,
                              top: 355,
                              child: Transform.scale(
                                scaleX: .955,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    state.description,
                                    key: ValueKey(state.description),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      height: 1,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 45.5,
                              top: 384.5,
                              child: ProcessingStatusCard(steps: state.steps),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

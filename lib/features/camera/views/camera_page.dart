import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodels/camera_view_model.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, this.classId, this.returnCapturedImage = false});

  final String? classId;
  final bool returnCapturedImage;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late final CameraViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = CameraViewModel()..initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _viewModel.pause();
    } else if (state == AppLifecycleState.resumed && !_viewModel.ready) {
      _viewModel.initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _viewModel,
    child: _CameraContent(
      classId: widget.classId,
      returnCapturedImage: widget.returnCapturedImage,
    ),
  );
}

class _CameraContent extends StatelessWidget {
  const _CameraContent({
    required this.classId,
    required this.returnCapturedImage,
  });

  final String? classId;
  final bool returnCapturedImage;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CameraViewModel>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (viewModel.ready)
            _CameraPreview(controller: viewModel.controller!)
          else if (viewModel.initializing)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            _CameraError(
              message: viewModel.error ?? 'Câmera indisponível.',
              onRetry: viewModel.initialize,
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _CameraAction(
                        tooltip: 'Voltar',
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (viewModel.ready && viewModel.canSwitchCamera) ...[
                        _CameraAction(
                          tooltip: viewModel.usingFrontCamera
                              ? 'Usar câmera traseira'
                              : 'Usar câmera frontal',
                          icon: Icons.cameraswitch_rounded,
                          onTap: viewModel.toggleCamera,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (viewModel.canUseFlash)
                        _CameraAction(
                          tooltip: 'Flash',
                          icon: viewModel.flashMode == FlashMode.off
                              ? Icons.flash_off_rounded
                              : Icons.flash_auto_rounded,
                          onTap: viewModel.toggleFlash,
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        returnCapturedImage
                            ? 'Enquadre o rosto do aluno'
                            : 'Enquadre todos os alunos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        returnCapturedImage
                            ? 'Use boa iluminação e deixe apenas um rosto visível.'
                            : 'Mantenha o aparelho firme e em boa iluminação.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .75),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                        button: true,
                        label: 'Capturar foto da turma',
                        child: GestureDetector(
                          onTap: viewModel.ready && !viewModel.capturing
                              ? () async {
                                  final file = await viewModel.capture();
                                  if (file == null || !context.mounted) return;
                                  if (returnCapturedImage) {
                                    Navigator.pop(context, file.path);
                                    return;
                                  }
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.processing,
                                    arguments: CameraResult(
                                      classId: classId,
                                      imagePath: file.path,
                                    ),
                                  );
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 76,
                            height: 76,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: viewModel.capturing
                                    ? AppColors.navInactive
                                    : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: viewModel.capturing
                                  ? const Padding(
                                      padding: EdgeInsets.all(15),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CameraResult {
  const CameraResult({required this.classId, required this.imagePath});
  final String? classId;
  final String imagePath;
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.controller});
  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = 1 / (controller.value.aspectRatio * size.aspectRatio);
    return ClipRect(
      child: Transform.scale(
        scale: scale < 1 ? 1 / scale : scale,
        child: Center(child: CameraPreview(controller)),
      ),
    );
  }
}

class _CameraAction extends StatelessWidget {
  const _CameraAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: Colors.black45,
      foregroundColor: Colors.white,
    ),
    icon: Icon(icon),
  );
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white,
            size: 54,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );
}

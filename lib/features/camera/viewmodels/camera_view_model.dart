import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraViewModel extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  CameraLensDirection _preferredLens = CameraLensDirection.back;
  bool _initializing = true;
  bool _capturing = false;
  String? _error;
  FlashMode _flashMode = FlashMode.off;
  bool _disposed = false;

  CameraController? get controller => _controller;
  bool get initializing => _initializing;
  bool get capturing => _capturing;
  String? get error => _error;
  FlashMode get flashMode => _flashMode;
  bool get ready => _controller?.value.isInitialized ?? false;
  bool get usingFrontCamera =>
      _controller?.description.lensDirection == CameraLensDirection.front;
  bool get canSwitchCamera =>
      _cameras.any(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      ) &&
      _cameras.any(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
  bool get canUseFlash => ready && !usingFrontCamera;

  Future<void> initialize() async {
    if (_disposed) return;
    await _controller?.dispose();
    _controller = null;
    _initializing = true;
    _error = null;
    notifyListeners();
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('noCamera', 'Nenhuma câmera encontrada.');
      }
      final preferred = _cameras.where(
        (camera) => camera.lensDirection == _preferredLens,
      );
      final selected = preferred.isEmpty ? _cameras.first : preferred.first;
      _preferredLens = selected.lensDirection;
      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }
      if (selected.lensDirection == CameraLensDirection.back) {
        await controller.setFlashMode(_flashMode);
      } else {
        _flashMode = FlashMode.off;
      }
      _controller = controller;
    } on CameraException catch (exception) {
      _error = switch (exception.code) {
        'CameraAccessDenied' =>
          'Permissão da câmera negada. Libere o acesso nas configurações.',
        'CameraAccessDeniedWithoutPrompt' =>
          'Acesso à câmera bloqueado nas configurações.',
        _ => exception.description ?? 'Não foi possível iniciar a câmera.',
      };
    } catch (_) {
      _error = 'Não foi possível iniciar a câmera neste dispositivo.';
    } finally {
      _initializing = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<void> pause() async {
    await _controller?.dispose();
    _controller = null;
  }

  Future<void> toggleFlash() async {
    if (!canUseFlash) return;
    _flashMode = _flashMode == FlashMode.off ? FlashMode.auto : FlashMode.off;
    await _controller!.setFlashMode(_flashMode);
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    if (!canSwitchCamera || _initializing || _capturing) return;
    _preferredLens = usingFrontCamera
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await initialize();
  }

  Future<XFile?> capture() async {
    if (!ready || _capturing) return null;
    _capturing = true;
    notifyListeners();
    try {
      return await _controller!.takePicture();
    } on CameraException catch (exception) {
      _error = exception.description ?? 'Não foi possível tirar a foto.';
      return null;
    } finally {
      _capturing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.dispose();
    super.dispose();
  }
}

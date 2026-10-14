import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraViewModel extends ChangeNotifier {
  CameraController? _controller;
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

  Future<void> initialize() async {
    if (_disposed) return;
    await _controller?.dispose();
    _controller = null;
    _initializing = true;
    _error = null;
    notifyListeners();
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'Nenhuma câmera encontrada.');
      }
      final preferred = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      final selected = preferred.isEmpty ? cameras.first : preferred.first;
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
      await controller.setFlashMode(_flashMode);
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
    if (!ready) return;
    _flashMode = _flashMode == FlashMode.off ? FlashMode.auto : FlashMode.off;
    await _controller!.setFlashMode(_flashMode);
    notifyListeners();
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

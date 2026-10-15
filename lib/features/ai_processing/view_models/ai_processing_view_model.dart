import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/facial_recognition_models.dart';
import '../../../data/services/facial_recognition_api.dart';
import '../models/ai_processing_state.dart';

typedef RoomAuditor = Future<RoomAuditResult> Function(String imagePath);

class AiProcessingViewModel extends ChangeNotifier {
  AiProcessingViewModel({
    required this.imagePath,
    required this._auditor,
    this.presentationDelay = const Duration(milliseconds: 350),
  });

  final String imagePath;
  final RoomAuditor _auditor;
  final Duration presentationDelay;

  AiProcessingState _state = const AiProcessingState.identifying();
  RoomAuditResult? _result;
  bool _running = false;
  bool _disposed = false;

  AiProcessingState get state => _state;
  RoomAuditResult? get result => _result;

  Future<void> start() async {
    if (_running || _state.isCompleted) return;
    _running = true;
    _result = null;
    _state = const AiProcessingState.identifying();
    _notify();

    try {
      final result = await _auditor(imagePath);
      if (_disposed) return;
      _result = result;
      _state = const AiProcessingState.preparing();
      _notify();
      await Future<void>.delayed(presentationDelay);
      if (_disposed) return;
      _state = const AiProcessingState.completed();
      _notify();
    } on FacialRecognitionException catch (error) {
      if (_disposed) return;
      _state = AiProcessingState.failed(error.message);
      _notify();
    } catch (_) {
      if (_disposed) return;
      _state = AiProcessingState.failed(
        'Ocorreu um erro inesperado ao processar a foto. Tente novamente.',
      );
      _notify();
    } finally {
      _running = false;
    }
  }

  Future<void> restart() => start();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ai_processing_state.dart';

class AiProcessingViewModel extends ChangeNotifier {
  AiProcessingViewModel({this.stepDuration = const Duration(seconds: 3)});

  final Duration stepDuration;
  AiProcessingState _state = const AiProcessingState.identifying();
  Timer? _timer;

  AiProcessingState get state => _state;

  void start() {
    if (_timer != null || _state.isCompleted) return;
    _scheduleNextStep();
  }

  void restart() {
    _timer?.cancel();
    _state = const AiProcessingState.identifying();
    notifyListeners();
    _scheduleNextStep();
  }

  void _scheduleNextStep() {
    _timer = Timer(stepDuration, _advance);
  }

  void _advance() {
    _timer = null;
    _state = switch (_state.phase) {
      AiProcessingPhase.identifying => const AiProcessingState.preparing(),
      AiProcessingPhase.preparing => const AiProcessingState.completed(),
      AiProcessingPhase.completed => _state,
    };
    notifyListeners();

    if (!_state.isCompleted) _scheduleNextStep();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

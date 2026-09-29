import 'package:class_vision/features/ai_processing/models/ai_processing_state.dart';
import 'package:class_vision/features/ai_processing/view_models/ai_processing_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes the processing state represented by the prototype', () {
    final viewModel = AiProcessingViewModel();
    addTearDown(viewModel.dispose);

    expect(viewModel.state.title, 'Analisando a sala...');
    expect(viewModel.state.steps, hasLength(4));
    expect(viewModel.state.steps.map((step) => step.status), [
      ProcessingStepStatus.completed,
      ProcessingStepStatus.completed,
      ProcessingStepStatus.active,
      ProcessingStepStatus.pending,
    ]);
  });

  test('reactively advances until the analysis is completed', () async {
    final viewModel = AiProcessingViewModel(
      stepDuration: const Duration(milliseconds: 10),
    );
    addTearDown(viewModel.dispose);

    viewModel.start();
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(viewModel.state.phase, AiProcessingPhase.preparing);

    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(viewModel.state.phase, AiProcessingPhase.completed);
    expect(viewModel.state.isCompleted, isTrue);
    expect(
      viewModel.state.steps.every(
        (step) => step.status == ProcessingStepStatus.completed,
      ),
      isTrue,
    );
  });
}

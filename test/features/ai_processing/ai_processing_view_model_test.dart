import 'package:class_vision/data/models/facial_recognition_models.dart';
import 'package:class_vision/data/services/facial_recognition_api.dart';
import 'package:class_vision/features/ai_processing/models/ai_processing_state.dart';
import 'package:class_vision/features/ai_processing/view_models/ai_processing_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const result = RoomAuditResult(
    message: 'Auditoria concluída.',
    recognizedStudents: [],
    unrecognizedCount: 0,
    totalFacesDetected: 0,
  );

  test('exposes the real processing state before sending the photo', () {
    final viewModel = AiProcessingViewModel(
      imagePath: 'sala.jpg',
      auditor: (_) async => result,
    );
    addTearDown(viewModel.dispose);

    expect(viewModel.state.title, 'Analisando a sala...');
    expect(viewModel.state.steps, hasLength(4));
    expect(viewModel.state.steps.map((step) => step.status), [
      ProcessingStepStatus.completed,
      ProcessingStepStatus.active,
      ProcessingStepStatus.pending,
      ProcessingStepStatus.pending,
    ]);
  });

  test('completes only after the facial API returns', () async {
    final viewModel = AiProcessingViewModel(
      imagePath: 'sala.jpg',
      auditor: (_) async => result,
      presentationDelay: Duration.zero,
    );
    addTearDown(viewModel.dispose);

    await viewModel.start();

    expect(viewModel.state.phase, AiProcessingPhase.completed);
    expect(viewModel.result, same(result));
    expect(
      viewModel.state.steps.every(
        (step) => step.status == ProcessingStepStatus.completed,
      ),
      isTrue,
    );
  });

  test('exposes a retryable error returned by the facial API', () async {
    final viewModel = AiProcessingViewModel(
      imagePath: 'sala.jpg',
      auditor: (_) async => throw const FacialRecognitionException('offline'),
      presentationDelay: Duration.zero,
    );
    addTearDown(viewModel.dispose);

    await viewModel.start();

    expect(viewModel.state.phase, AiProcessingPhase.failed);
    expect(viewModel.state.description, 'offline');
    expect(viewModel.result, isNull);
  });
}

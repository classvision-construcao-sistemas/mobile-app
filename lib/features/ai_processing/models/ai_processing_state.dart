enum ProcessingStepStatus { completed, active, pending }

enum AiProcessingPhase { identifying, preparing, completed }

class ProcessingStep {
  const ProcessingStep({required this.label, required this.status});

  final String label;
  final ProcessingStepStatus status;
}

class AiProcessingState {
  const AiProcessingState({
    required this.phase,
    required this.title,
    required this.description,
    required this.steps,
  });

  const AiProcessingState.identifying()
    : phase = AiProcessingPhase.identifying,
      title = 'Analisando a sala...',
      description = 'Comparando os rostos detectados com a lista da turma.',
      steps = const [
        ProcessingStep(
          label: 'Foto recebida',
          status: ProcessingStepStatus.completed,
        ),
        ProcessingStep(
          label: 'Rostos detectados',
          status: ProcessingStepStatus.completed,
        ),
        ProcessingStep(
          label: 'Identificando alunos',
          status: ProcessingStepStatus.active,
        ),
        ProcessingStep(
          label: 'Preparando conferência',
          status: ProcessingStepStatus.pending,
        ),
      ];

  const AiProcessingState.preparing()
    : phase = AiProcessingPhase.preparing,
      title = 'Preparando conferência...',
      description = 'Organizando os dados identificados para sua revisão.',
      steps = const [
        ProcessingStep(
          label: 'Foto recebida',
          status: ProcessingStepStatus.completed,
        ),
        ProcessingStep(
          label: 'Rostos detectados',
          status: ProcessingStepStatus.completed,
        ),
        ProcessingStep(
          label: 'Identificando alunos',
          status: ProcessingStepStatus.completed,
        ),
        ProcessingStep(
          label: 'Preparando conferência',
          status: ProcessingStepStatus.active,
        ),
      ];

  const AiProcessingState.completed()
    : phase = AiProcessingPhase.completed,
      title = 'Análise concluída!',
      description = 'A conferência está pronta para ser revisada.',
      steps = const [
        ProcessingStep(
          label: 'Foto recebida',
          status: ProcessingStepStatus.completed,
        ),
        ProcessingStep(
          label: 'Rostos detectados',
          status: ProcessingStepStatus.completed,
        ),
        ProcessingStep(
          label: 'Identificando alunos',
          status: ProcessingStepStatus.completed,
        ),
        ProcessingStep(
          label: 'Preparando conferência',
          status: ProcessingStepStatus.completed,
        ),
      ];

  final AiProcessingPhase phase;
  final String title;
  final String description;
  final List<ProcessingStep> steps;

  bool get isCompleted => phase == AiProcessingPhase.completed;
}

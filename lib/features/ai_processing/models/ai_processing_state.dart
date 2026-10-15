enum ProcessingStepStatus { completed, active, pending, failed }

enum AiProcessingPhase { identifying, preparing, completed, failed }

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
      description = 'Enviando a foto e comparando os rostos cadastrados.',
      steps = const [
        ProcessingStep(
          label: 'Foto recebida',
          status: ProcessingStepStatus.completed,
        ),
        ProcessingStep(
          label: 'Detectando rostos',
          status: ProcessingStepStatus.active,
        ),
        ProcessingStep(
          label: 'Identificando alunos',
          status: ProcessingStepStatus.pending,
        ),
        ProcessingStep(
          label: 'Preparando conferência',
          status: ProcessingStepStatus.pending,
        ),
      ];

  const AiProcessingState.preparing()
    : phase = AiProcessingPhase.preparing,
      title = 'Preparando conferência...',
      description = 'Organizando os resultados para sua revisão.',
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
          label: 'Alunos identificados',
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
      description = 'A chamada está pronta para ser revisada.',
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
          label: 'Alunos identificados',
          status: ProcessingStepStatus.completed,
        ),
        ProcessingStep(
          label: 'Conferência preparada',
          status: ProcessingStepStatus.completed,
        ),
      ];

  AiProcessingState.failed(String message)
    : phase = AiProcessingPhase.failed,
      title = 'Não foi possível analisar',
      description = message,
      steps = const [
        ProcessingStep(
          label: 'Foto recebida',
          status: ProcessingStepStatus.completed,
        ),
        ProcessingStep(
          label: 'Reconhecimento facial',
          status: ProcessingStepStatus.failed,
        ),
        ProcessingStep(
          label: 'Identificando alunos',
          status: ProcessingStepStatus.pending,
        ),
        ProcessingStep(
          label: 'Preparando conferência',
          status: ProcessingStepStatus.pending,
        ),
      ];

  final AiProcessingPhase phase;
  final String title;
  final String description;
  final List<ProcessingStep> steps;

  bool get isCompleted => phase == AiProcessingPhase.completed;
  bool get hasFailed => phase == AiProcessingPhase.failed;
}

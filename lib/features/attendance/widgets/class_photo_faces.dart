import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/photo.dart';
import '../../../data/models/facial_recognition_models.dart';

/// Foto da sala com um quadro em cada rosto detectado e o nome do aluno
/// reconhecido, para o coordenador conferir de olho o que a IA encontrou.
class ClassPhotoFaces extends StatefulWidget {
  const ClassPhotoFaces({
    super.key,
    required this.imagePath,
    required this.faces,
    required this.nameFor,
    this.maxHeight = 320,
    this.image,
  });

  final String imagePath;
  final List<DetectedFace> faces;

  /// Nome a mostrar para a matrícula (ou nulo se não houver).
  final String? Function(String studentId) nameFor;
  final double maxHeight;

  /// Imagem a usar no lugar da foto em [imagePath] (testes).
  final ImageProvider? image;

  @override
  State<ClassPhotoFaces> createState() => _ClassPhotoFacesState();
}

class _ClassPhotoFacesState extends State<ClassPhotoFaces> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _size;
  bool _failed = false;

  ImageProvider get _provider =>
      widget.image ?? photoProvider(widget.imagePath);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(ClassPhotoFaces oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.image != widget.image) {
      _resolve();
    }
  }

  void _resolve() {
    final stream = _provider.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stop();
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(
          () => _size = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          ),
        );
      },
      onError: (_, _) {
        if (mounted) setState(() => _failed = true);
      },
    );
    _stream = stream..addListener(_listener!);
  }

  void _stop() {
    if (_listener != null) _stream?.removeListener(_listener!);
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    final size = _size;
    final recognized = widget.faces
        .where((face) => face.status == FaceStatus.recognized)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: size == null
                ? const SizedBox(
                    height: 180,
                    child: ColoredBox(
                      color: AppColors.divider,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                : Center(
                    heightFactor: 1,
                    child: AspectRatio(
                      aspectRatio: size.width / size.height,
                      child: LayoutBuilder(
                        builder: (context, box) => Stack(
                          children: [
                            Positioned.fill(
                              child: Image(image: _provider, fit: BoxFit.fill),
                            ),
                            for (final face in widget.faces)
                              ..._faceMarks(face, box.biggest, _label(face)),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.faces.isEmpty)
          const Text(
            'A marcação dos rostos não está disponível para esta foto.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          )
        else
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _Legend(color: AppColors.success, text: '$recognized da turma'),
              if (widget.faces.any((f) => f.status == FaceStatus.outsideClass))
                const _Legend(color: AppColors.warning, text: 'De outra turma'),
              if (widget.faces.any((f) => f.status == FaceStatus.unidentified))
                const _Legend(color: AppColors.error, text: 'Não identificado'),
            ],
          ),
      ],
    );
  }

  String _label(DetectedFace face) => switch (face.status) {
    FaceStatus.recognized =>
      _firstName(widget.nameFor(face.studentId ?? '')) ??
          face.studentId ??
          'Aluno',
    FaceStatus.outsideClass => 'Outra turma',
    FaceStatus.unidentified => '?',
  };

  static String? _firstName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

Color _colorFor(FaceStatus status) => switch (status) {
  FaceStatus.recognized => AppColors.success,
  FaceStatus.outsideClass => AppColors.warning,
  FaceStatus.unidentified => AppColors.error,
};

/// Quadro do rosto e, acima dele, a etiqueta com o nome; se o rosto estiver
/// colado no topo da foto, a etiqueta vai para dentro do quadro.
List<Widget> _faceMarks(DetectedFace face, Size area, String label) {
  final color = _colorFor(face.status);
  final left = face.x * area.width;
  final top = face.y * area.height;
  final labelOnTop = top >= 22;
  return [
    Positioned(
      left: left,
      top: top,
      width: face.width * area.width,
      height: face.height * area.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
    Positioned(
      left: left,
      top: labelOnTop ? top - 22 : top + 2,
      child: Semantics(
        label: label,
        child: _Tag(text: label, color: color),
      ),
    ),
  ];
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 20,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      maxLines: 1,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    ],
  );
}

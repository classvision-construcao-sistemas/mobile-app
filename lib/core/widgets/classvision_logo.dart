import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Marca do ClassVision: o enquadramento da câmera (cantos) com o "check"
/// da presença confirmada. É o mesmo desenho de `design/brand/
/// classvision-icon.svg`, usado nos ícones do app, do site e do favicon.
class ClassVisionMark extends StatelessWidget {
  const ClassVisionMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: const CustomPaint(painter: _MarkPainter()),
  );
}

/// Marca + nome "ClassVision".
class ClassVisionLogo extends StatelessWidget {
  const ClassVisionLogo({
    super.key,
    this.onDark = false,
    this.compact = false,
    this.size,
  });

  final bool onDark;
  final bool compact;

  /// Altura da marca; o texto acompanha a proporção.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final mark = size ?? (compact ? 34.0 : 38.0);
    return Semantics(
      label: 'ClassVision',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClassVisionMark(size: mark),
          SizedBox(width: mark * .32),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Class'),
                    TextSpan(
                      text: 'Vision',
                      style: TextStyle(
                        color: onDark
                            ? AppColors.primaryLight
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(
                  color: onDark ? Colors.white : AppColors.textPrimary,
                  fontSize: mark * .58,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Coordenadas do SVG original (512 × 512).
    final scale = size.shortestSide / 512;
    canvas.scale(scale);

    const rect = Rect.fromLTWH(0, 0, 512, 512);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(116)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ).createShader(rect),
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    stroke
      ..color = const Color(0xFFBFDBFE)
      ..strokeWidth = 34;
    for (final corner in _corners) {
      canvas.drawPath(corner, stroke);
    }

    stroke
      ..color = Colors.white
      ..strokeWidth = 46;
    canvas.drawPath(
      Path()
        ..moveTo(176, 260)
        ..lineTo(234, 316)
        ..lineTo(340, 200),
      stroke,
    );
  }

  static final _corners = [
    Path()
      ..moveTo(118, 202)
      ..lineTo(118, 148)
      ..quadraticBezierTo(118, 118, 148, 118)
      ..lineTo(202, 118),
    Path()
      ..moveTo(310, 118)
      ..lineTo(364, 118)
      ..quadraticBezierTo(394, 118, 394, 148)
      ..lineTo(394, 202),
    Path()
      ..moveTo(394, 310)
      ..lineTo(394, 364)
      ..quadraticBezierTo(394, 394, 364, 394)
      ..lineTo(310, 394),
    Path()
      ..moveTo(202, 394)
      ..lineTo(148, 394)
      ..quadraticBezierTo(118, 394, 118, 364)
      ..lineTo(118, 310),
  ];

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}

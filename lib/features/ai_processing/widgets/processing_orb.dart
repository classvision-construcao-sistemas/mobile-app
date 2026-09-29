import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ProcessingOrb extends StatefulWidget {
  const ProcessingOrb({super.key});

  @override
  State<ProcessingOrb> createState() => _ProcessingOrbState();
}

class _ProcessingOrbState extends State<ProcessingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 1,
      end: .94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'IA processando',
      image: true,
      child: Container(
        width: 104,
        height: 104,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Text(
              'IA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: -.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

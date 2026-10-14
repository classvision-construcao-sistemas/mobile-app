import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.onCamera,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onCamera;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Início'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Turmas'),
    (Icons.camera_alt_outlined, Icons.camera_alt_rounded, 'Câmera'),
    (Icons.history_outlined, Icons.history_rounded, 'Histórico'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 16,
    shadowColor: Colors.black26,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 72,
        child: Row(
          children: List.generate(_items.length, (index) {
            if (index == 2) {
              return Expanded(
                child: Semantics(
                  button: true,
                  label: 'Câmera',
                  child: InkWell(
                    onTap: onCamera,
                    child: Transform.translate(
                      offset: const Offset(0, -14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: .28,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Câmera',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            final selected = currentIndex == index;
            final item = _items[index];
            return Expanded(
              child: InkWell(
                onTap: () => onSelected(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        selected ? item.$2 : item.$1,
                        key: ValueKey(selected),
                        size: 23,
                        color: selected
                            ? AppColors.primary
                            : AppColors.navInactive,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$3,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? AppColors.primary
                            : AppColors.navInactive,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}

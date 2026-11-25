import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Início'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Turmas'),
    (Icons.fact_check_outlined, Icons.fact_check_rounded, 'Chamadas'),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Relatórios'),
    (Icons.more_horiz_rounded, Icons.more_horiz_rounded, 'Mais'),
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
                        fontSize: 12,
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

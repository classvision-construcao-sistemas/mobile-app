import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Item do bottom navigation
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Bottom Navigation Bar customizado do ClassVision
///
/// Possui 5 itens com o botão central da câmera em destaque.
class AppBottomNavBar extends StatelessWidget {
  /// Índice atualmente selecionado
  final int currentIndex;

  /// Callback ao selecionar um item
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<NavItem> _items = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Início',
    ),
    NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Turmas',
    ),
    NavItem(
      icon: Icons.camera_alt_outlined,
      activeIcon: Icons.camera_alt_rounded,
      label: 'Câmera',
    ),
    NavItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
      label: 'Histórico',
    ),
    NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_items.length, (index) {
              if (index == 2) {
                // Botão central da câmera
                return Expanded(
                  child: _CenterCameraButton(
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                );
              }
              return Expanded(
                child: _NavBarItem(
                  item: _items[index],
                  isActive: currentIndex == index,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Item padrão do bottom nav
class _NavBarItem extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.navActive : AppColors.navInactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (isActive
                      ? AppTextStyles.navLabelActive
                      : AppTextStyles.navLabel)
                  .copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão central destacado da câmera
class _CenterCameraButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _CenterCameraButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Câmera',
            style: AppTextStyles.navLabelActive.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

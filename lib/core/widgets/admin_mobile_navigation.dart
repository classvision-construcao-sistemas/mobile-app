import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'admin_page_scaffold.dart';

class AdminMobileNavigation extends StatelessWidget {
  const AdminMobileNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AdminDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Material(
    key: const Key('admin-mobile-navigation'),
    color: Colors.white,
    elevation: 12,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 74,
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        destinations[index].icon,
                        size: 22,
                        color: selectedIndex == index
                            ? AppColors.primary
                            : AppColors.navInactive,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        destinations[index].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: selectedIndex == index
                              ? AppColors.primary
                              : AppColors.navInactive,
                          fontWeight: selectedIndex == index
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

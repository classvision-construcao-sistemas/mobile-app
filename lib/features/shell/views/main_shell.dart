import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/viewmodels/main_shell_view_model.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../classes/views/classes_page.dart';
import '../../history/views/history_page.dart';
import '../../home/view/home_page.dart';
import '../../profile/views/profile_page.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => MainShellViewModel(),
    child: const _MainShellContent(),
  );
}

class _MainShellContent extends StatelessWidget {
  const _MainShellContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MainShellViewModel>();
    void openCamera() => Navigator.pushNamed(context, AppRoutes.camera);

    final pages = [
      HomePage(onOpenCamera: openCamera),
      const ClassesPage(),
      const SizedBox.shrink(),
      const HistoryPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: viewModel.index, children: pages),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: viewModel.index,
        onSelected: viewModel.select,
        onCamera: openCamera,
      ),
    );
  }
}

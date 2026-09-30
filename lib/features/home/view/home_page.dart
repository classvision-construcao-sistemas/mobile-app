import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodel/home_view_model.dart';
import 'widgets/greeting_header.dart';
import 'widgets/ai_call_card.dart';
import 'widgets/class_card.dart';
import 'widgets/app_bottom_nav_bar.dart';

/// Tela principal (Início) do ClassVision
///
/// Segue o padrão MVVM, consumindo dados do [HomeViewModel]
/// através do Provider.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Inicializa o ViewModel após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const _HomeShimmer();
            }
            return _HomeContent(viewModel: viewModel);
          },
        ),
      ),
      bottomNavigationBar: Consumer<HomeViewModel>(
        builder: (context, viewModel, _) {
          return AppBottomNavBar(
            currentIndex: viewModel.currentNavIndex,
            onTap: viewModel.setNavIndex,
          );
        },
      ),
    );
  }
}

/// Conteúdo principal da tela quando carregado
class _HomeContent extends StatelessWidget {
  final HomeViewModel viewModel;

  const _HomeContent({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saudação
          GreetingHeader(
            greetingText: viewModel.greetingText,
            dateText: viewModel.formattedDate,
          ),
          const SizedBox(height: 24),

          // Card de IA
          AiCallCard(
            onOpenCamera: viewModel.onOpenCamera,
          ),
          const SizedBox(height: 24),

          // Lista de turmas
          ...viewModel.classes.map(
            (classItem) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClassCard(
                classItem: classItem,
                onTap: () => viewModel.onClassTap(classItem),
              ),
            ),
          ),

          // Espaço extra no final para evitar sobreposição do nav
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Skeleton/Shimmer de carregamento
class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer do greeting
          _ShimmerBox(width: 200, height: 28),
          const SizedBox(height: 8),
          _ShimmerBox(width: 180, height: 16),
          const SizedBox(height: 24),

          // Shimmer do card IA
          _ShimmerBox(width: double.infinity, height: 160, radius: 20),
          const SizedBox(height: 24),

          // Shimmer dos cards de turma
          _ShimmerBox(width: double.infinity, height: 100, radius: 16),
          const SizedBox(height: 12),
          _ShimmerBox(width: double.infinity, height: 100, radius: 16),
        ],
      ),
    );
  }
}

/// Widget de shimmer (skeleton) simples
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

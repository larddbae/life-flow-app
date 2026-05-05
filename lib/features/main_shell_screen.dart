import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/providers/nav_bar_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';
import 'package:life_flow/features/finance/screens/finance_screen.dart';
import 'package:life_flow/features/projects/screens/project_board_screen.dart';
import 'package:life_flow/features/reflection/screens/reflection_screen.dart';
import 'package:life_flow/features/routines/screens/routines_screen.dart';
import 'package:life_flow/features/today_nexus/screens/today_nexus_screen.dart';
import 'package:life_flow/shared/widgets/custom_bottom_nav_bar.dart';

// =============================================================================
// MainShellScreen — Root scaffold with IndexedStack + bottom nav bar
// Manages page switching via navBarIndexProvider. All 5 feature screens
// stay alive in the stack to preserve scroll position & state.
// =============================================================================

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  /// The 5 feature screens, indexed to match kNavBarItems order.
  static const List<Widget> _screens = [
    TodayNexusScreen(), // 0 — Dashboard
    FinanceScreen(), // 1 — Finance
    ProjectBoardScreen(), // 2 — Board
    RoutinesScreen(), // 3 — Routines
    ReflectionScreen(), // 4 — Reflect
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navBarIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      // extendBody allows content to paint behind the translucent nav bar
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navBarIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}

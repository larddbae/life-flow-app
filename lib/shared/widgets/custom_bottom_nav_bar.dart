import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// CustomBottomNavBar — Pill-shaped navigation bar (docked at bottom)
// Shared across all screens via MainShellScreen's Scaffold.bottomNavigationBar.
// =============================================================================

/// Data model for a single navigation item.
class NavBarItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavBarItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Predefined navigation items for the LifeFlow app.
const List<NavBarItemData> kNavBarItems = [
  NavBarItemData(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: 'Dashboard',
  ),
  NavBarItemData(
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet,
    label: 'Finance',
  ),
  NavBarItemData(
    icon: Icons.view_kanban_outlined,
    activeIcon: Icons.view_kanban,
    label: 'Board',
  ),
  NavBarItemData(
    icon: Icons.check_circle_outline,
    activeIcon: Icons.check_circle,
    label: 'Routines',
  ),
  NavBarItemData(
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics,
    label: 'Reflect',
  ),
];

/// A pill-shaped bottom navigation bar designed for Scaffold.bottomNavigationBar.
///
/// Mirrors the Stitch design: #1E1E1E/95% opacity bg, #3A3A3A border,
/// backdrop blur, centered at bottom with 92% width.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Outer container provides padding from screen edges and bottom safe area
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.chipRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceNavigation.withValues(alpha: 0.95),
              borderRadius: AppRadius.chipRadius,
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 30,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(kNavBarItems.length, (index) {
                final item = kNavBarItems[index];
                final isActive = index == currentIndex;

                return _NavBarIcon(
                  item: item,
                  isActive: isActive,
                  onTap: () => onTap(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual icon button inside the nav bar.
class _NavBarIcon extends StatelessWidget {
  final NavBarItemData item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarIcon({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentIndigo.withValues(alpha: 0.10)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isActive ? item.activeIcon : item.icon,
          color: isActive
              ? AppColors.accentIndigo
              : const Color(0xFF6B6B6B), // gray-500 equivalent
          size: 24,
        ),
      ),
    );
  }
}

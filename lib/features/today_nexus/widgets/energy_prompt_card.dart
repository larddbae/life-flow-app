import 'package:flutter/material.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// EnergyPromptCard — "How's your energy today?" battery selector
// Stateful because it manages the local selection animation.
// =============================================================================

/// A card presenting 5 battery-level icons for the user to select their
/// current energy level. Mirrors the Stitch design with indigo highlight
/// ring on the selected level.
///
/// ```dart
/// EnergyPromptCard(
///   selectedLevel: 3,
///   onLevelSelected: (level) => /* update state */,
/// )
/// ```
class EnergyPromptCard extends StatelessWidget {
  /// Currently selected energy level (1–5), or null if none selected.
  final int? selectedLevel;

  /// Callback when the user taps an energy level.
  final ValueChanged<int> onLevelSelected;

  const EnergyPromptCard({
    super.key,
    this.selectedLevel,
    required this.onLevelSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "How's your energy today?",
            style: AppTextStyles.bodyMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final level = index + 1;
                return _EnergyBatteryButton(
                  level: level,
                  isSelected: selectedLevel == level,
                  onTap: () => onLevelSelected(level),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual battery icon button with selection state.
///
/// Selected state: indigo bg at 20%, indigo ring at 50%, scale 1.1,
/// filled icon variant. Unselected: text-secondary, no background.
class _EnergyBatteryButton extends StatelessWidget {
  final int level;
  final bool isSelected;
  final VoidCallback onTap;

  const _EnergyBatteryButton({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  /// Maps energy level 1–5 to the corresponding Material battery icon.
  IconData get _icon {
    return switch (level) {
      1 => Icons.battery_0_bar,
      2 => Icons.battery_2_bar,
      3 => Icons.battery_4_bar,
      4 => Icons.battery_5_bar,
      5 => Icons.battery_full,
      _ => Icons.battery_unknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(10),
        transform: isSelected
            ? Matrix4.diagonal3Values(1.1, 1.1, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentIndigo.withValues(alpha: 0.20)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: AppColors.accentIndigo.withValues(alpha: 0.50),
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          _icon,
          color: isSelected ? AppColors.accentIndigo : AppColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// HabitQuickCheckTile — Tap-to-complete habit tile for Today Nexus
// Shows habit title, completion checkbox, and optional progress metadata.
// =============================================================================

class HabitQuickCheckTile extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final String moduleType; // 'boolean', 'timer', 'counter'
  final int? targetValue;
  final int? recordedValue;
  final VoidCallback onToggle;

  const HabitQuickCheckTile({
    super.key,
    required this.title,
    required this.isCompleted,
    required this.moduleType,
    this.targetValue,
    this.recordedValue,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.statusSuccess.withValues(alpha: 0.08)
              : AppColors.surfaceCard,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isCompleted
                ? AppColors.statusSuccess.withValues(alpha: 0.30)
                : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // ── Animated Checkbox ────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.statusSuccess
                    : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.statusSuccess
                      : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // ── Title ────────────────────────────────────────────────
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMd.copyWith(
                  decoration:
                      isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),

            // ── Module indicator (timer/counter badge) ───────────────
            if (moduleType != 'boolean' && targetValue != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.chipRadius,
                ),
                child: Text(
                  _buildMetaLabel(),
                  style: AppTextStyles.metadata.copyWith(fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildMetaLabel() {
    final current = recordedValue ?? 0;
    final target = targetValue ?? 0;
    if (moduleType == 'timer') {
      return '${current}m / ${target}m';
    }
    return '$current / $target';
  }
}

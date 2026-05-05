import 'package:flutter/material.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// ScheduleTimelineTile — Single item in the "Today's Schedule" list
// Color-coded left border, time, title, and category chip.
// =============================================================================

/// A timeline tile showing a scheduled activity with a colored accent border.
///
/// Mirrors the Stitch design: #2D2D2D card with a 4px colored left strip,
/// time label (metadata), activity title (body-md), and a category chip.
///
/// ```dart
/// ScheduleTimelineTile(
///   time: '09:00',
///   title: 'Deep Work Session',
///   category: 'Focus',
///   accentColor: AppColors.accentIndigo,
/// )
/// ```
class ScheduleTimelineTile extends StatelessWidget {
  final String time;
  final String title;
  final String category;
  final Color accentColor;

  const ScheduleTimelineTile({
    super.key,
    required this.time,
    required this.title,
    required this.category,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Stack(
        children: [
          // ── Colored left accent strip ──────────────────────────────────
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              color: accentColor,
            ),
          ),

          // ── Content row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Time label — right-aligned in a fixed-width box
                SizedBox(
                  width: 48,
                  child: Text(
                    time,
                    style: AppTextStyles.metadata,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 16),

                // Activity title — fills remaining space
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodyMd,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 12),

                // Category chip
                _CategoryChip(label: category),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill chip showing the activity category.
///
/// Surface-variant background, subtle border, 10px text.
class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.metadata.copyWith(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

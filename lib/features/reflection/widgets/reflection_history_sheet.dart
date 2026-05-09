import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/providers/reflection_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// ReflectionHistorySheet — Scrollable bottom sheet showing past reflections.
// Displays all DailyLog entries with journal notes, sorted by date descending.
// =============================================================================

class ReflectionHistorySheet extends ConsumerWidget {
  const ReflectionHistorySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReflectionHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(reflectionHistoryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Drag Handle ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Title ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: AppColors.accentIndigo, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Reflection History',
                      style: AppTextStyles.headlineLg.copyWith(fontSize: 20),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.borderSubtle, height: 1),

              // ── List ─────────────────────────────────────────────────────
              Expanded(
                child: historyAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accentIndigo),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error loading history',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
                  ),
                  data: (logs) {
                    if (logs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_note, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              'No reflections yet',
                              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your saved reflections will appear here.',
                              style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final parts = (log.journalNotes ?? '').split(' ||| ');
                        final wentWell = parts.isNotEmpty ? parts[0].trim() : '';
                        final toImprove = parts.length > 1 ? parts[1].trim() : '';

                        final dateLabel = _formatDate(log.id);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date header
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14, color: AppColors.accentIndigo),
                                  const SizedBox(width: 8),
                                  Text(
                                    dateLabel,
                                    style: AppTextStyles.bodySm.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentIndigo,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Energy badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.energyColor(log.energyLevel)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bolt,
                                            size: 12,
                                            color: AppColors.energyColor(
                                                log.energyLevel)),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${log.energyLevel}/5',
                                          style: AppTextStyles.metadata.copyWith(
                                            color: AppColors.energyColor(
                                                log.energyLevel),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // What went well
                              if (wentWell.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  '✅ What went well',
                                  style: AppTextStyles.metadata.copyWith(
                                    color: AppColors.statusSuccess,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  wentWell,
                                  style: AppTextStyles.bodySm
                                      .copyWith(color: AppColors.textPrimary),
                                ),
                              ],

                              // What to improve
                              if (toImprove.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  '🔄 What to improve',
                                  style: AppTextStyles.metadata.copyWith(
                                    color: AppColors.statusWarning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  toImprove,
                                  style: AppTextStyles.bodySm
                                      .copyWith(color: AppColors.textPrimary),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Formats a "YYYY-MM-DD" date string into a readable label.
  String _formatDate(String dateId) {
    try {
      final date = DateTime.parse(dateId);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      const weekdays = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday',
      ];
      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateId;
    }
  }
}

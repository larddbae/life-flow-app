import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/providers/habit_provider.dart';
import 'package:life_flow/core/models/habit.dart';
import 'package:life_flow/core/theme/app_theme.dart';
import 'package:life_flow/features/routines/widgets/add_habit_sheet.dart';

// =============================================================================
// RoutinesScreen — Habits and weekly templates (RESTORED UI)
// =============================================================================

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSheet(context, const AddHabitSheet()),
        backgroundColor: AppColors.accentIndigo,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Routines', style: AppTextStyles.headlineXl),
                  const SizedBox(height: 24),
                  
                  // ── Weekday Strip ──────────────────────────────────────────
                  const _WeekdayStrip(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),

            // ── Today's Habits List ──────────────────────────────────────────
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              sliver: _TodayHabitsSliver(),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── 30-Day Activity Heatmap ───────────────────────────────
                  const _HeatmapWidget(),
                  const SizedBox(height: 32),

                  // ── Weekly Template Builder Button ────────────────────────
                  const _WeeklyTemplateButton(),
                ]),
              ),
            ),

            // Bottom clearance for nav bar
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => sheet,
    );
  }
}

// =============================================================================
// Weekday Strip
// =============================================================================

class _WeekdayStrip extends StatelessWidget {
  const _WeekdayStrip();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final date = monday.add(Duration(days: index));
          final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
          final dayLetter = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];

          return Column(
            children: [
              Text(
                dayLetter,
                style: AppTextStyles.labelCaps.copyWith(
                  color: isToday ? AppColors.accentIndigo : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigo.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${date.day}',
                    style: AppTextStyles.metadata.copyWith(color: AppColors.textPrimary),
                  ),
                )
              else
                Text(
                  '${date.day}',
                  style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// =============================================================================
// Today's Habits
// =============================================================================

class _TodayHabitsSliver extends ConsumerWidget {
  const _TodayHabitsSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitProvider);

    return habitsAsync.when(
      loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (habits) {
        if (habits.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text('No habits scheduled for today.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final h = habits[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HabitCard(
                  progress: h,
                  onToggle: () => ref.read(habitProvider.notifier).toggleCompletion(h.habit.id),
                  onIncrement: () {
                    final val = h.todayValue ?? 0;
                    ref.read(habitProvider.notifier).recordValue(h.habit.id, val + 1);
                  },
                  onDecrement: () {
                    final val = h.todayValue ?? 0;
                    ref.read(habitProvider.notifier).recordValue(h.habit.id, max(0, val - 1));
                  },
                ),
              );
            },
            childCount: habits.length,
          ),
        );
      },
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitWithStatus progress;
  final VoidCallback onToggle;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _HabitCard({
    required this.progress,
    required this.onToggle,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final habit = progress.habit;
    final isCompleted = progress.isCompletedToday;
    final val = progress.todayValue ?? 0;

    String emoji = '💪';
    Color lineColor = AppColors.tertiary;

    if (isCompleted) {
      lineColor = AppColors.statusSuccess;
    } else if (habit.moduleType == ModuleType.counter) {
      emoji = '📖';
      lineColor = AppColors.accentIndigo;
    } else if (habit.moduleType == ModuleType.timer) {
      emoji = '🍅';
      lineColor = AppColors.energy1;
    }

    Widget actionWidget = const SizedBox.shrink();
    Widget bottomWidget = const SizedBox.shrink();

    if (habit.moduleType == ModuleType.boolean) {
      actionWidget = GestureDetector(
        onTap: onToggle,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.accentIndigo : Colors.transparent,
            shape: BoxShape.circle,
            border: isCompleted
                ? null
                : Border.all(color: AppColors.borderSubtle, width: 2),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      );
    } else if (habit.moduleType == ModuleType.counter) {
      actionWidget = GestureDetector(
        onTap: onToggle,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.accentIndigo : Colors.transparent,
            shape: BoxShape.circle,
            border: isCompleted
                ? null
                : Border.all(color: AppColors.borderSubtle, width: 2),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      );

      final target = habit.targetValue ?? 1;
      bottomWidget = Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('$val / $target', style: AppTextStyles.metadata),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onDecrement,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text('-', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    ),
                  ),
                  Container(width: 1, height: 16, color: AppColors.borderSubtle),
                  GestureDetector(
                    onTap: onIncrement,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text('+', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (habit.moduleType == ModuleType.timer) {
      actionWidget = GestureDetector(
        onTap: onToggle,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.accentIndigo : Colors.transparent,
            shape: BoxShape.circle,
            border: isCompleted
                ? null
                : Border.all(color: AppColors.borderSubtle, width: 2),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      );

      bottomWidget = Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow, size: 16, color: AppColors.accentIndigo),
                    const SizedBox(width: 8),
                    Text('Start Focus', style: AppTextStyles.labelCaps.copyWith(color: AppColors.accentIndigo)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: lineColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(emoji, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.title,
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: isCompleted ? AppColors.textPrimary.withValues(alpha: 0.7) : AppColors.textPrimary,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              Text(
                                '${habit.frequencyType == FrequencyType.daily ? 'Daily' : 'Specific Days'}${habit.targetValue != null ? ' · ${habit.targetValue} Target' : ''}',
                                style: AppTextStyles.metadata,
                              ),
                            ],
                          ),
                        ),
                        actionWidget,
                      ],
                    ),
                    bottomWidget,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Heatmap Widget
// =============================================================================

class _HeatmapWidget extends StatelessWidget {
  const _HeatmapWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30-Day Activity Heatmap', style: AppTextStyles.labelCaps),
              Text('12 Day Streak 🔥', style: AppTextStyles.metadata.copyWith(color: AppColors.accentIndigo)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 35,
            itemBuilder: (context, index) {
              Color cellColor = AppColors.accentIndigo;
              BoxBorder? border;

              if (index >= 32) {
                cellColor = AppColors.surfaceContainer.withValues(alpha: 0.2);
              } else if (index == 31) {
                cellColor = AppColors.surfaceContainer;
                border = Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.5));
              } else {
                int mod = index % 5;
                if (mod == 0) {
                  cellColor = AppColors.surfaceContainer;
                } else if (mod == 1) {
                  cellColor = AppColors.accentIndigo.withValues(alpha: 0.4);
                } else {
                  cellColor = AppColors.accentIndigo;
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(4),
                  border: border,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: AppTextStyles.metadata.copyWith(fontSize: 10)),
              const SizedBox(width: 4),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.accentIndigo.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.accentIndigo, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('More', style: AppTextStyles.metadata.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Weekly Template Builder Button
// =============================================================================

class _WeeklyTemplateButton extends StatelessWidget {
  const _WeeklyTemplateButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('⚙️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text('Weekly Template Builder', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

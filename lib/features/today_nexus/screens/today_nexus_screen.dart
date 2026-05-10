import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/project_task.dart';
import 'package:life_flow/core/providers/budget_provider.dart';
import 'package:life_flow/core/providers/daily_log_provider.dart';
import 'package:life_flow/core/providers/habit_provider.dart';
import 'package:life_flow/core/providers/project_task_provider.dart';
import 'package:life_flow/core/providers/transaction_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';
import 'package:life_flow/features/today_nexus/widgets/energy_prompt_card.dart';
import 'package:life_flow/features/today_nexus/widgets/financial_glance_card.dart';
import 'package:life_flow/features/today_nexus/widgets/habit_quick_check.dart';
import 'package:life_flow/features/today_nexus/widgets/schedule_timeline_tile.dart';
import 'package:life_flow/shared/widgets/section_label.dart';

// =============================================================================
// TodayNexusScreen — The central dashboard hub (LIVE)
// Now a ConsumerWidget reading from Riverpod providers.
// =============================================================================

class TodayNexusScreen extends ConsumerWidget {
  const TodayNexusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: AppSpacing.containerPadding,
        right: AppSpacing.containerPadding,
        top: 16,
        bottom: 120, // clearance for floating bottom nav
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Greeting + Avatar ─────────────────────────
            const _HeaderSection(),
            const SizedBox(height: AppSpacing.stackGap),

            // ── Energy Prompt Card (LIVE) ─────────────────────────
            const _LiveEnergyPrompt(),
            const SizedBox(height: AppSpacing.sectionMargin),

            // ── Today's Tasks (LIVE) ──────────────────────────────
            const _LiveTasksSection(),
            const SizedBox(height: AppSpacing.stackGap + 8),

            // ── Habit Quick-Check (LIVE) ──────────────────────────
            const _LiveHabitSection(),
            const SizedBox(height: AppSpacing.stackGap + 8),

            // ── Financial Glance (LIVE) ───────────────────────────
            const _LiveFinancialGlance(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Private Sub-Sections — each is a ConsumerWidget reading its own provider
// =============================================================================

/// Header showing dynamic greeting, date, and user avatar.
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: AppTextStyles.headlineXl,
          ),
          const SizedBox(height: 4),
          Text(
            _getFormattedDate(),
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a time-appropriate greeting string.
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Returns the current date formatted like "Sunday, May 4".
  String _getFormattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday, $month ${now.day}';
  }
}

/// LIVE Energy Prompt — reads/writes to dailyLogProvider.
class _LiveEnergyPrompt extends ConsumerWidget {
  const _LiveEnergyPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLogAsync = ref.watch(dailyLogProvider);

    final selectedLevel = dailyLogAsync.whenOrNull(
      data: (log) => log?.energyLevel,
    );

    return EnergyPromptCard(
      selectedLevel: selectedLevel,
      onLevelSelected: (level) {
        ref.read(dailyLogProvider.notifier).setEnergyLevel(level);
      },
    );
  }
}

/// LIVE Today's Tasks — reads from todayTasksProvider.
class _LiveTasksSection extends ConsumerWidget {
  const _LiveTasksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todayTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(text: "Today's Tasks"),
        const SizedBox(height: AppSpacing.itemGapSm),
        tasksAsync.when(
          loading: () => const _TasksLoadingShimmer(),
          error: (e, _) => Text('Error loading tasks',
              style: AppTextStyles.metadata
                  .copyWith(color: AppColors.statusDanger)),
          data: (tasks) {
            if (tasks.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: AppRadius.cardRadius,
                  border:
                      Border.all(color: AppColors.borderSubtle, width: 1),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 32,
                        color: AppColors.statusSuccess.withValues(alpha: 0.6)),
                    const SizedBox(height: 8),
                    Text(
                      'No tasks scheduled for today',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Schedule tasks from the Board tab',
                      style: AppTextStyles.metadata,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: tasks.map((task) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskTile(task: task, ref: ref),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/// A single task tile displayed in the Today Nexus schedule.
class _TaskTile extends StatelessWidget {
  final ProjectTask task;
  final WidgetRef ref;

  const _TaskTile({required this.task, required this.ref});

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority) {
      TaskPriority.high => AppColors.statusDanger,
      TaskPriority.medium => AppColors.tertiary,
      TaskPriority.low => AppColors.statusSuccess,
    };

    final hasSpecificTime = task.dueDate != null &&
        (task.dueDate!.hour != 0 || task.dueDate!.minute != 0);

    return ScheduleTimelineTile(
      time: hasSpecificTime
          ? '${task.dueDate!.hour.toString().padLeft(2, '0')}:${task.dueDate!.minute.toString().padLeft(2, '0')}'
          : null,
      title: task.title,
      category: task.priority.name.toUpperCase(),
      accentColor: priorityColor,
    );
  }
}

/// Loading shimmer for tasks section.
class _TasksLoadingShimmer extends StatelessWidget {
  const _TasksLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(2, (_) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
          ),
        );
      }),
    );
  }
}

/// LIVE Habit Quick-Check — reads from habitProvider.
class _LiveHabitSection extends ConsumerWidget {
  const _LiveHabitSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitProvider);

    return habitsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (habits) {
        if (habits.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel(text: "Habit Quick-Check"),
            const SizedBox(height: AppSpacing.itemGapSm),
            ...habits.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HabitQuickCheckTile(
                    title: h.habit.title,
                    isCompleted: h.isCompletedToday,
                    moduleType: h.habit.moduleType.name,
                    targetValue: h.habit.targetValue,
                    recordedValue: h.todayValue,
                    onToggle: () {
                      ref
                          .read(habitProvider.notifier)
                          .toggleCompletion(h.habit.id);
                    },
                  ),
                )),
          ],
        );
      },
    );
  }
}

/// LIVE Financial Glance — reads from transactionProvider.
class _LiveFinancialGlance extends ConsumerWidget {
  const _LiveFinancialGlance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(transactionProvider);

    if (txnAsync.isLoading) {
      return const FinancialGlanceCard(
        label: 'Daily Budget Remaining',
        amount: '...',
        progress: 0,
      );
    }

    if (txnAsync.hasError) {
      return const FinancialGlanceCard(
        label: 'Daily Budget Remaining',
        amount: 'Error',
        progress: 0,
      );
    }

    final txnState = txnAsync.value!;

    final monthlyBalance = txnState.monthlyBalance;

    final now = DateTime.now();
    int daysRemaining = DateUtils.getDaysInMonth(now.year, now.month) - now.day;
    if (daysRemaining <= 0) daysRemaining = 1; // prevent division by zero

    double safeToSpendToday = 0;
    if (monthlyBalance > 0) {
      safeToSpendToday = monthlyBalance / daysRemaining;
    }
    
    // Progress calculation for today's spending relative to today's safe limit
    final dailyLimit = safeToSpendToday + txnState.todayExpenses;
    final progress = dailyLimit > 0 ? txnState.todayExpenses / dailyLimit : 0.0;

    return FinancialGlanceCard(
      label: 'Daily Budget Remaining',
      amount: _formatCurrency(safeToSpendToday),
      progress: progress,
    );
  }

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final abs = amount.abs();
    final formatted = 'Rp ${_formatNumber(abs.round())}';
    return isNegative ? '-$formatted' : formatted;
  }

  String _formatNumber(int n) {
    final str = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

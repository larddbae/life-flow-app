

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/providers/habit_provider.dart';
import 'package:life_flow/core/models/habit.dart';
import 'package:life_flow/core/theme/app_theme.dart';
import 'package:life_flow/features/routines/widgets/add_habit_sheet.dart';
import 'package:life_flow/features/routines/widgets/manage_habits_sheet.dart';

// =============================================================================
// RoutinesScreen — Habits and weekly templates (FULLY INTERACTIVE)
// =============================================================================

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90), // Offset for CustomBottomNavBar
        child: GestureDetector(
          onTap: () => _showSheet(context, const AddHabitSheet()),
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.accentIndigo,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
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

                  // ── Weekday Strip + Calendar Picker ─────────────────────
                  const _WeekdayStrip(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),

            // ── Section Header for Habits ────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, _) {
                    final selectedDate = ref.watch(routineDateProvider);
                    final now = DateTime.now();
                    final isToday = selectedDate.year == now.year &&
                        selectedDate.month == now.month &&
                        selectedDate.day == now.day;

                    final label = isToday
                        ? "Today's Active Habits"
                        : '${_monthName(selectedDate.month)} ${selectedDate.day} Habits';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(label, style: AppTextStyles.headlineLg),
                    );
                  },
                ),
              ),
            ),

            // ── Habits List ──────────────────────────────────────────────
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              sliver: _TodayHabitsSliver(),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Activity Heatmap ────────────────────────────────────
                  const _HeatmapWidget(),
                  const SizedBox(height: 32),

                  // ── Weekly Template Builder Button ──────────────────────
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

  static String _monthName(int month) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month];
  }
}

// =============================================================================
// Weekday Strip — Interactive date selector with calendar picker
// =============================================================================

class _WeekdayStrip extends ConsumerWidget {
  const _WeekdayStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(routineDateProvider);
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          // ── Calendar Picker Icon ────────────────────────────────────
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.accentIndigo,
                        onPrimary: Colors.white,
                        surface: AppColors.surfaceCard,
                        onSurface: AppColors.textPrimary,
                      ),
                      dialogTheme: DialogThemeData(
                        backgroundColor: AppColors.surfaceCard,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                final normalized = DateTime(picked.year, picked.month, picked.day);
                ref.read(routineDateProvider.notifier).state = normalized;
                ref.read(habitProvider.notifier).refresh();
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentIndigo.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today,
                  size: 16, color: AppColors.accentIndigo),
            ),
          ),
          const SizedBox(width: 8),

          // ── Day Chips (scrollable to prevent overflow) ───────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  final date = monday.add(Duration(days: index));
                  final isSelected = date.year == selectedDate.year &&
                      date.month == selectedDate.month &&
                      date.day == selectedDate.day;
                  final now = DateTime.now();
                  final isToday = date.day == now.day &&
                      date.month == now.month &&
                      date.year == now.year;
                  final dayLetter = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];

                  return GestureDetector(
                    onTap: () {
                      final normalized =
                          DateTime(date.year, date.month, date.day);
                      ref.read(routineDateProvider.notifier).state = normalized;
                      ref.read(habitProvider.notifier).refresh();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentIndigo.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.accentIndigo
                                    .withValues(alpha: 0.4))
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayLetter,
                            style: AppTextStyles.labelCaps.copyWith(
                              color: isSelected
                                  ? AppColors.accentIndigo
                                  : isToday
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentIndigo
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isToday && !isSelected
                                  ? Border.all(
                                      color: AppColors.accentIndigo
                                          .withValues(alpha: 0.5),
                                      width: 1.5)
                                  : null,
                            ),
                            child: Text(
                              '${date.day}',
                              style: AppTextStyles.metadata.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Today's Habits — Reactive list filtered by routineDateProvider
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text('No habits scheduled for this day.',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                ],
              ),
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
                  onToggle: () => ref
                      .read(habitProvider.notifier)
                      .toggleCompletion(h.habit.id),
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

// _HabitCard — Uniform minimalist checklist card for all habit types.
class _HabitCard extends StatelessWidget {
  final HabitWithStatus progress;
  final VoidCallback onToggle;

  const _HabitCard({
    required this.progress,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final habit = progress.habit;
    final isCompleted = progress.isCompletedToday;

    // Pick accent colour based on type (line indicator only)
    Color lineColor;
    String emoji;
    if (isCompleted) {
      lineColor = AppColors.statusSuccess;
      emoji = habit.moduleType == ModuleType.timer
          ? '🍅'
          : habit.moduleType == ModuleType.counter
              ? '📖'
              : '💪';
    } else if (habit.moduleType == ModuleType.counter) {
      emoji = '📖';
      lineColor = AppColors.accentIndigo;
    } else if (habit.moduleType == ModuleType.timer) {
      emoji = '🍅';
      lineColor = AppColors.energy1;
    } else {
      emoji = '💪';
      lineColor = AppColors.tertiary;
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
            // Coloured left accent bar
            Container(width: 4, color: lineColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // ── Emoji avatar ──────────────────────────────────
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child:
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 16),

                    // ── Title + description ───────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            habit.title,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: isCompleted
                                  ? AppColors.textPrimary
                                      .withValues(alpha: 0.5)
                                  : AppColors.textPrimary,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${habit.frequencyType == FrequencyType.daily ? 'Daily' : 'Specific Days'}'
                            '${habit.targetValue != null ? ' · ${habit.targetValue} Target' : ''}',
                            style: AppTextStyles.metadata,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Universal circular checkbox ───────────────────
                    GestureDetector(
                      onTap: onToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.accentIndigo
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isCompleted
                              ? null
                              : Border.all(
                                  color: AppColors.borderSubtle, width: 2),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
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
// Heatmap Widget — Real data with month navigation
// =============================================================================

class _HeatmapWidget extends ConsumerWidget {
  const _HeatmapWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(heatmapMonthProvider);
    final heatmapAsync = ref.watch(heatmapDataProvider);

    final monthName = _fullMonthName(month.month);
    final year = month.year;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          // ── Month Navigation Header ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  final prev = DateTime(month.year, month.month - 1);
                  ref.read(heatmapMonthProvider.notifier).state = prev;
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_left,
                      size: 20, color: AppColors.textSecondary),
                ),
              ),
              Text(
                '$monthName $year',
                style: AppTextStyles.bodyMd
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: () {
                  final next = DateTime(month.year, month.month + 1);
                  ref.read(heatmapMonthProvider.notifier).state = next;
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Weekday Headers ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => SizedBox(
                      width: 28,
                      child: Center(
                        child: Text(d,
                            style: AppTextStyles.metadata
                                .copyWith(fontSize: 10)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // ── Heatmap Grid ────────────────────────────────────────────
          heatmapAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(
              height: 120,
              child: Center(child: Text('Error loading data')),
            ),
            data: (days) {
              // Calculate offset for the first day of the month
              final firstDayWeekday =
                  DateTime(month.year, month.month, 1).weekday; // 1=Mon
              final offset = firstDayWeekday - 1; // blanks before day 1
              final totalCells = offset + days.length;
              final rows = (totalCells / 7).ceil();
              final gridCount = rows * 7;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: gridCount,
                itemBuilder: (context, index) {
                  if (index < offset || index >= offset + days.length) {
                    // Empty cell (padding)
                    return const SizedBox.shrink();
                  }

                  final dayData = days[index - offset];
                  final pct = dayData.completionPct;
                  final now = DateTime.now();
                  final isToday = dayData.date.year == now.year &&
                      dayData.date.month == now.month &&
                      dayData.date.day == now.day;

                  Color cellColor;
                  if (pct <= 0) {
                    cellColor = AppColors.surfaceContainer;
                  } else if (pct < 0.34) {
                    cellColor =
                        AppColors.accentIndigo.withValues(alpha: 0.25);
                  } else if (pct < 0.67) {
                    cellColor =
                        AppColors.accentIndigo.withValues(alpha: 0.55);
                  } else {
                    cellColor = AppColors.accentIndigo;
                  }

                  BoxBorder? border;
                  if (isToday) {
                    border = Border.all(
                        color: AppColors.accentIndigo, width: 1.5);
                  }

                  return Tooltip(
                    message:
                        '${dayData.date.day}/${dayData.date.month} — ${(pct * 100).round()}%',
                    child: Container(
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(4),
                        border: border,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),

          // ── Legend ───────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less',
                  style: AppTextStyles.metadata.copyWith(fontSize: 10)),
              const SizedBox(width: 4),
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: AppColors.accentIndigo.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: AppColors.accentIndigo.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: AppColors.accentIndigo,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('More',
                  style: AppTextStyles.metadata.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  String _fullMonthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month];
  }
}

// =============================================================================
// Weekly Template Builder Button — Opens ManageHabitsSheet
// =============================================================================

class _WeeklyTemplateButton extends StatelessWidget {
  const _WeeklyTemplateButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surfaceCard,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const ManageHabitsSheet(),
        );
      },
      child: Container(
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
                Text('Weekly Template Builder',
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

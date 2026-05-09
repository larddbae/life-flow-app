import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/daily_log.dart';
import 'package:life_flow/core/models/project_task.dart';
import 'package:life_flow/core/providers/daily_log_provider.dart';
import 'package:life_flow/core/providers/database_provider.dart';
import 'package:life_flow/core/providers/habit_provider.dart';

// =============================================================================
// Reflection Providers — Aggregated analytics for the Reflection screen.
// All providers react to reflectionMonthProvider for month-based filtering.
// =============================================================================

// ─── Month Selector ─────────────────────────────────────────────────────────

/// Controls which month the Reflection screen is displaying.
/// Defaults to the current month. Month navigator arrows mutate this.
final reflectionMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

// ─── At-a-Glance Metrics ────────────────────────────────────────────────────

/// Composite metrics shown in the "At a Glance" summary cards.
class ReflectionMetrics {
  final int habitCompletionPct;   // 0–100
  final int incomeSavedPct;       // 0–100
  final int longestStreakDays;

  const ReflectionMetrics({
    this.habitCompletionPct = 0,
    this.incomeSavedPct = 0,
    this.longestStreakDays = 0,
  });
}

/// Aggregates habit completion %, income saved %, and longest streak
/// for the selected reflection month.
final reflectionMetricsProvider = FutureProvider<ReflectionMetrics>((ref) async {
  final month = ref.watch(reflectionMonthProvider);
  final year = month.year;
  final mon = month.month;
  final daysInMonth = DateTime(year, mon + 1, 0).day;

  final habitRepo = ref.read(habitRepositoryProvider);
  final execRepo = ref.read(habitExecutionRepositoryProvider);
  final txnRepo = ref.read(transactionRepositoryProvider);

  // ── 1. Habit Completion % ───────────────────────────────────────────────
  final allHabits = await habitRepo.getAll();
  int totalScheduled = 0;
  int totalCompleted = 0;

  if (allHabits.isNotEmpty) {
    final start = DateTime(year, mon, 1);
    final end = DateTime(year, mon, daysInMonth, 23, 59, 59);
    final monthExecs = await execRepo.getByDateRange(start, end);

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, mon, d);
      final weekday = date.weekday;
      final activeHabits = allHabits.where((h) => h.isActiveOn(weekday)).toList();
      totalScheduled += activeHabits.length;

      final dateStr =
          '$year-${mon.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      final dayCompletedIds = monthExecs
          .where((e) =>
              e.executionDate.toIso8601String().startsWith(dateStr) &&
              e.isCompleted)
          .map((e) => e.habitId)
          .toSet();
      totalCompleted +=
          activeHabits.where((h) => dayCompletedIds.contains(h.id)).length;
    }
  }

  final habitPct =
      totalScheduled > 0 ? (totalCompleted / totalScheduled * 100).round() : 0;

  // ── 2. Income Saved % ──────────────────────────────────────────────────
  final monthStart = DateTime(year, mon, 1);
  final monthEnd = DateTime(year, mon, daysInMonth, 23, 59, 59);
  final monthTxns = await txnRepo.getByDateRange(monthStart, monthEnd);

  double totalIncome = 0;
  double totalSavings = 0;
  for (final txn in monthTxns) {
    if (txn.type.name == 'income') {
      totalIncome += txn.amount;
    }
    // Savings = transactions that fund a wishlist (expenses allocated to savings)
    if (txn.wishlistId != null) {
      totalSavings += txn.amount;
    }
  }

  final savedPct =
      totalIncome > 0 ? (totalSavings / totalIncome * 100).round().clamp(0, 100) : 0;

  // ── 3. Longest Streak ──────────────────────────────────────────────────
  // For each habit, compute the maximum consecutive days completed
  // from the past year through the end of the selected month.
  int longestStreak = 0;

  if (allHabits.isNotEmpty) {
    final streakEnd = DateTime(year, mon, daysInMonth, 23, 59, 59);
    final streakStart = streakEnd.subtract(const Duration(days: 365));
    final allExecs = await execRepo.getByDateRange(streakStart, streakEnd);

    for (final habit in allHabits) {
      final habitExecs = allExecs
          .where((e) => e.habitId == habit.id && e.isCompleted)
          .map((e) {
            final d = e.executionDate;
            return DateTime(d.year, d.month, d.day);
          })
          .toSet()
          .toList()
        ..sort();

      int currentStreak = 0;
      int maxStreak = 0;

      for (int i = 0; i < habitExecs.length; i++) {
        if (i == 0) {
          currentStreak = 1;
        } else {
          final diff = habitExecs[i].difference(habitExecs[i - 1]).inDays;
          if (diff == 1) {
            currentStreak++;
          } else {
            currentStreak = 1;
          }
        }
        if (currentStreak > maxStreak) maxStreak = currentStreak;
      }
      if (maxStreak > longestStreak) longestStreak = maxStreak;
    }
  }

  return ReflectionMetrics(
    habitCompletionPct: habitPct,
    incomeSavedPct: savedPct,
    longestStreakDays: longestStreak,
  );
});

// ─── Productivity vs. Energy Chart Data ─────────────────────────────────────

/// Data for a single day on the Productivity vs. Energy chart.
class ChartDayData {
  final int day;         // 1-based day of month
  final int energyLevel; // 1–5 (0 = no data)
  final int tasksCompleted;

  const ChartDayData({
    required this.day,
    this.energyLevel = 0,
    this.tasksCompleted = 0,
  });
}

/// Returns per-day energy levels and task completion counts for the chart.
final reflectionChartDataProvider =
    FutureProvider<List<ChartDayData>>((ref) async {
  final month = ref.watch(reflectionMonthProvider);
  final year = month.year;
  final mon = month.month;
  final daysInMonth = DateTime(year, mon + 1, 0).day;

  final dailyLogRepo = ref.read(dailyLogRepositoryProvider);
  final taskRepo = ref.read(projectTaskRepositoryProvider);

  // Fetch daily logs for the month
  final logs = await dailyLogRepo.getByMonth(year, mon);
  final logMap = <int, int>{}; // day -> energyLevel
  for (final log in logs) {
    final day = int.tryParse(log.id.substring(8, 10)) ?? 0;
    if (day > 0) logMap[day] = log.energyLevel;
  }

  // Fetch all tasks and filter for 'done' in this month
  // We use scheduledDate to determine the day a task was completed on
  final allTasks = await taskRepo.getAll();
  final doneTasks = allTasks.where((t) =>
      t.status == TaskStatus.done && t.scheduledDate != null).toList();

  final taskCounts = <int, int>{}; // day -> count
  for (final task in doneTasks) {
    final sd = task.scheduledDate!;
    if (sd.year == year && sd.month == mon) {
      taskCounts[sd.day] = (taskCounts[sd.day] ?? 0) + 1;
    }
  }

  return List.generate(daysInMonth, (i) {
    final day = i + 1;
    return ChartDayData(
      day: day,
      energyLevel: logMap[day] ?? 0,
      tasksCompleted: taskCounts[day] ?? 0,
    );
  });
});

// ─── Habit Consistency Heatmap (Reflection-scoped) ──────────────────────────

/// Reuses HeatmapDayData from habit_provider but bound to reflectionMonthProvider.
final reflectionHeatmapProvider =
    FutureProvider<List<HeatmapDayData>>((ref) async {
  // Invalidate when habits change
  ref.watch(habitProvider);

  final month = ref.watch(reflectionMonthProvider);
  final habitRepo = ref.read(habitRepositoryProvider);
  final execRepo = ref.read(habitExecutionRepositoryProvider);

  final year = month.year;
  final mon = month.month;
  final daysInMonth = DateTime(year, mon + 1, 0).day;

  final allHabits = await habitRepo.getAll();
  if (allHabits.isEmpty) {
    return List.generate(
      daysInMonth,
      (i) => HeatmapDayData(
          date: DateTime(year, mon, i + 1), completionPct: 0),
    );
  }

  final start = DateTime(year, mon, 1);
  final end = DateTime(year, mon, daysInMonth, 23, 59, 59);
  final monthExecs = await execRepo.getByDateRange(start, end);

  final result = <HeatmapDayData>[];
  for (int d = 1; d <= daysInMonth; d++) {
    final date = DateTime(year, mon, d);
    final weekday = date.weekday;

    final activeHabits =
        allHabits.where((h) => h.isActiveOn(weekday)).toList();
    if (activeHabits.isEmpty) {
      result.add(HeatmapDayData(date: date, completionPct: 0));
      continue;
    }

    final dateStr =
        '$year-${mon.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    final dayExecs = monthExecs
        .where((e) =>
            e.executionDate.toIso8601String().startsWith(dateStr) &&
            e.isCompleted)
        .toList();

    final completedIds = dayExecs.map((e) => e.habitId).toSet();
    final completed =
        activeHabits.where((h) => completedIds.contains(h.id)).length;
    final pct = completed / activeHabits.length;

    result.add(HeatmapDayData(date: date, completionPct: pct));
  }

  return result;
});

// ─── Reflection History ─────────────────────────────────────────────────────

/// All DailyLog entries that contain journal text, sorted by date descending.
final reflectionHistoryProvider =
    FutureProvider<List<DailyLog>>((ref) async {
  // Re-fetch whenever the daily log for today changes (e.g. after saving)
  ref.watch(dailyLogProvider);

  final repo = ref.read(dailyLogRepositoryProvider);
  final all = await repo.getAll();
  return all
      .where((log) =>
          log.journalNotes != null && log.journalNotes!.trim().isNotEmpty)
      .toList();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/habit.dart';
import 'package:life_flow/core/models/habit_execution.dart';
import 'package:life_flow/core/providers/database_provider.dart';
import 'package:uuid/uuid.dart';

// =============================================================================
// HabitWithStatus — Composite model pairing a Habit with today's execution.
// =============================================================================

class HabitWithStatus {
  final Habit habit;
  final HabitExecution? todayExecution;

  const HabitWithStatus({
    required this.habit,
    this.todayExecution,
  });

  /// Whether the habit is completed today.
  bool get isCompletedToday => todayExecution?.isCompleted ?? false;

  /// Today's recorded value (for counter/timer habits).
  int? get todayValue => todayExecution?.recordedValue;
}

// =============================================================================
// routineDateProvider — Selected date for Routines screen filtering.
// Defaults to today. Updated by tapping weekday strip or calendar picker.
// =============================================================================

final routineDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// =============================================================================
// heatmapMonthProvider — Tracks which month the heatmap card is displaying.
// =============================================================================

final heatmapMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

// =============================================================================
// HeatmapDayData — Completion percentage for a single day.
// =============================================================================

class HeatmapDayData {
  final DateTime date;
  final double completionPct; // 0.0 – 1.0

  const HeatmapDayData({required this.date, required this.completionPct});
}

// =============================================================================
// heatmapDataProvider — Loads completion data for the selected heatmap month.
// Returns a list of HeatmapDayData, one per day in the month.
// =============================================================================

final heatmapDataProvider = FutureProvider<List<HeatmapDayData>>((ref) async {
  // Re-compute whenever habitProvider refreshes (add/toggle/delete)
  ref.watch(habitProvider);

  final month = ref.watch(heatmapMonthProvider);
  final habitRepo = ref.read(habitRepositoryProvider);
  final execRepo = ref.read(habitExecutionRepositoryProvider);

  final year = month.year;
  final mon = month.month;
  final daysInMonth = DateTime(year, mon + 1, 0).day;

  final allHabits = await habitRepo.getAll();
  if (allHabits.isEmpty) {
    return List.generate(
      daysInMonth,
      (i) => HeatmapDayData(date: DateTime(year, mon, i + 1), completionPct: 0),
    );
  }

  // Fetch all executions for the entire month in one query
  final start = DateTime(year, mon, 1);
  final end = DateTime(year, mon, daysInMonth, 23, 59, 59);
  final monthExecs = await execRepo.getByDateRange(start, end);

  final result = <HeatmapDayData>[];
  for (int d = 1; d <= daysInMonth; d++) {
    final date = DateTime(year, mon, d);
    final weekday = date.weekday;

    // Find habits active on this weekday
    final activeHabits = allHabits.where((h) => h.isActiveOn(weekday)).toList();
    if (activeHabits.isEmpty) {
      result.add(HeatmapDayData(date: date, completionPct: 0));
      continue;
    }

    // Find completed executions for this day
    final dateStr =
        '${year}-${mon.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    final dayExecs = monthExecs
        .where((e) => e.executionDate.toIso8601String().startsWith(dateStr) && e.isCompleted)
        .toList();

    final completedIds = dayExecs.map((e) => e.habitId).toSet();
    final completed = activeHabits.where((h) => completedIds.contains(h.id)).length;
    final pct = completed / activeHabits.length;

    result.add(HeatmapDayData(date: date, completionPct: pct));
  }

  return result;
});

// =============================================================================
// HabitNotifier — Manages habits and their daily execution state.
// Loads habits for the selected date with their completion status on build.
// =============================================================================

class HabitNotifier extends AsyncNotifier<List<HabitWithStatus>> {
  @override
  Future<List<HabitWithStatus>> build() async {
    return _loadHabitsForDate();
  }

  /// Loads habits active on the selected date with execution data.
  Future<List<HabitWithStatus>> _loadHabitsForDate() async {
    final habitRepo = ref.read(habitRepositoryProvider);
    final execRepo = ref.read(habitExecutionRepositoryProvider);
    final selectedDate = ref.read(routineDateProvider);

    final activeHabits = await habitRepo.getActiveForDay(selectedDate.weekday);
    final dayExecs = await execRepo.getByDate(selectedDate);

    return activeHabits.map((habit) {
      final exec = dayExecs.where((e) => e.habitId == habit.id).firstOrNull;
      return HabitWithStatus(habit: habit, todayExecution: exec);
    }).toList();
  }

  /// Refresh from the currently selected date.
  Future<void> refresh() async {
    state = AsyncData(await _loadHabitsForDate());
  }

  /// Add a new habit template.
  Future<void> addHabit({
    required String title,
    FrequencyType frequencyType = FrequencyType.daily,
    List<int> activeDays = const [],
    ModuleType moduleType = ModuleType.boolean,
    int? targetValue,
  }) async {
    final repo = ref.read(habitRepositoryProvider);
    final habit = Habit(
      id: const Uuid().v4(),
      title: title,
      frequencyType: frequencyType,
      activeDays: activeDays,
      moduleType: moduleType,
      targetValue: targetValue,
    );
    await repo.insert(habit);
    state = AsyncData(await _loadHabitsForDate());
  }

  /// Toggle a habit's completion for the selected date.
  Future<void> toggleCompletion(String habitId) async {
    final execRepo = ref.read(habitExecutionRepositoryProvider);
    final selectedDate = ref.read(routineDateProvider);
    final existing = await execRepo.getByHabitAndDate(habitId, selectedDate);

    if (existing != null) {
      // Toggle: completed ↔ not completed
      await execRepo.update(
          existing.copyWith(isCompleted: !existing.isCompleted));
    } else {
      // First tap: mark as completed
      final exec = HabitExecution(
        id: const Uuid().v4(),
        habitId: habitId,
        executionDate: selectedDate,
        isCompleted: true,
      );
      await execRepo.insert(exec);
    }
    state = AsyncData(await _loadHabitsForDate());
  }

  /// Record a value for a counter/timer habit (e.g., pages read, minutes).
  Future<void> recordValue(String habitId, int value) async {
    final execRepo = ref.read(habitExecutionRepositoryProvider);
    final selectedDate = ref.read(routineDateProvider);
    final existing = await execRepo.getByHabitAndDate(habitId, selectedDate);

    if (existing != null) {
      await execRepo.update(existing.copyWith(
        recordedValue: value,
        isCompleted: true,
      ));
    } else {
      final exec = HabitExecution(
        id: const Uuid().v4(),
        habitId: habitId,
        executionDate: selectedDate,
        isCompleted: true,
        recordedValue: value,
      );
      await execRepo.insert(exec);
    }
    state = AsyncData(await _loadHabitsForDate());
  }

  /// Update a habit template.
  Future<void> updateHabit(Habit habit) async {
    final repo = ref.read(habitRepositoryProvider);
    await repo.update(habit);
    state = AsyncData(await _loadHabitsForDate());
  }

  /// Delete a habit (cascades to all executions).
  Future<void> deleteHabit(String id) async {
    final repo = ref.read(habitRepositoryProvider);
    await repo.delete(id);
    state = AsyncData(await _loadHabitsForDate());
  }

  /// Get consistency percentage for a habit in a given month.
  Future<double> getMonthlyConsistency(
      String habitId, int year, int month) async {
    final execRepo = ref.read(habitExecutionRepositoryProvider);
    final completions =
        await execRepo.getMonthlyCompletionCount(habitId, year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return completions / daysInMonth;
  }
}

/// Provider for habits filtered by the selected routine date.
final habitProvider =
    AsyncNotifierProvider<HabitNotifier, List<HabitWithStatus>>(() {
  return HabitNotifier();
});

/// All habit templates (not filtered by today's weekday).
final allHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  // Invalidate when habitProvider changes (add/edit/delete)
  ref.watch(habitProvider);
  final repo = ref.watch(habitRepositoryProvider);
  return repo.getAll();
});

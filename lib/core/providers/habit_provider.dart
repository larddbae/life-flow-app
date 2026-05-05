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
// HabitNotifier — Manages habits and their daily execution state.
// Loads today's active habits with their completion status on build.
// =============================================================================

class HabitNotifier extends AsyncNotifier<List<HabitWithStatus>> {
  @override
  Future<List<HabitWithStatus>> build() async {
    return _loadTodayHabits();
  }

  Future<List<HabitWithStatus>> _loadTodayHabits() async {
    final habitRepo = ref.read(habitRepositoryProvider);
    final execRepo = ref.read(habitExecutionRepositoryProvider);
    final now = DateTime.now();

    final activeHabits = await habitRepo.getActiveForDay(now.weekday);
    final todayExecs = await execRepo.getByDate(now);

    return activeHabits.map((habit) {
      final exec = todayExecs.where((e) => e.habitId == habit.id).firstOrNull;
      return HabitWithStatus(habit: habit, todayExecution: exec);
    }).toList();
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
    state = AsyncData(await _loadTodayHabits());
  }

  /// Toggle a habit's completion for today (tap-to-complete).
  Future<void> toggleCompletion(String habitId) async {
    final execRepo = ref.read(habitExecutionRepositoryProvider);
    final now = DateTime.now();
    final existing = await execRepo.getByHabitAndDate(habitId, now);

    if (existing != null) {
      // Toggle: completed ↔ not completed
      await execRepo.update(
          existing.copyWith(isCompleted: !existing.isCompleted));
    } else {
      // First tap: mark as completed
      final exec = HabitExecution(
        id: const Uuid().v4(),
        habitId: habitId,
        executionDate: now,
        isCompleted: true,
      );
      await execRepo.insert(exec);
    }
    state = AsyncData(await _loadTodayHabits());
  }

  /// Record a value for a counter/timer habit (e.g., pages read, minutes).
  Future<void> recordValue(String habitId, int value) async {
    final execRepo = ref.read(habitExecutionRepositoryProvider);
    final now = DateTime.now();
    final existing = await execRepo.getByHabitAndDate(habitId, now);

    if (existing != null) {
      await execRepo.update(existing.copyWith(
        recordedValue: value,
        isCompleted: true,
      ));
    } else {
      final exec = HabitExecution(
        id: const Uuid().v4(),
        habitId: habitId,
        executionDate: now,
        isCompleted: true,
        recordedValue: value,
      );
      await execRepo.insert(exec);
    }
    state = AsyncData(await _loadTodayHabits());
  }

  /// Update a habit template.
  Future<void> updateHabit(Habit habit) async {
    final repo = ref.read(habitRepositoryProvider);
    await repo.update(habit);
    state = AsyncData(await _loadTodayHabits());
  }

  /// Delete a habit (cascades to all executions).
  Future<void> deleteHabit(String id) async {
    final repo = ref.read(habitRepositoryProvider);
    await repo.delete(id);
    state = AsyncData(await _loadTodayHabits());
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

/// Provider for today's habits with their execution status.
final habitProvider =
    AsyncNotifierProvider<HabitNotifier, List<HabitWithStatus>>(() {
  return HabitNotifier();
});

/// All habit templates (not filtered by today's weekday).
final allHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  return repo.getAll();
});

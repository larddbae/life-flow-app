import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/daily_log.dart';
import 'package:life_flow/core/providers/database_provider.dart';

// =============================================================================
// DailyLogNotifier — Manages today's energy level and journal entry.
// Loads/creates the DailyLog for the current date on build.
// =============================================================================

class DailyLogNotifier extends AsyncNotifier<DailyLog?> {
  @override
  Future<DailyLog?> build() async {
    final repo = ref.watch(dailyLogRepositoryProvider);
    final todayId = _todayId();
    return repo.getByDate(todayId);
  }

  /// Set or update today's energy level (1–5).
  Future<void> setEnergyLevel(int level) async {
    final repo = ref.read(dailyLogRepositoryProvider);
    final todayId = _todayId();
    final existing = state.valueOrNull;

    if (existing != null) {
      final updated = existing.copyWith(energyLevel: level);
      await repo.update(updated);
      state = AsyncData(updated);
    } else {
      final now = DateTime.now();
      final newLog = DailyLog(
        id: todayId,
        energyLevel: level,
        createdAt: DateTime(now.year, now.month, now.day),
      );
      await repo.insert(newLog);
      state = AsyncData(newLog);
    }
  }

  /// Update today's journal notes.
  Future<void> updateJournal(String notes) async {
    final repo = ref.read(dailyLogRepositoryProvider);
    final todayId = _todayId();
    final existing = state.valueOrNull;

    if (existing != null) {
      final updated = existing.copyWith(journalNotes: notes);
      await repo.update(updated);
      state = AsyncData(updated);
    } else {
      final now = DateTime.now();
      final newLog = DailyLog(
        id: todayId,
        energyLevel: 3, // default mid-level
        journalNotes: notes,
        createdAt: DateTime(now.year, now.month, now.day),
      );
      await repo.insert(newLog);
      state = AsyncData(newLog);
    }
  }

  /// Get all logs for a given month (for Reflection analytics).
  Future<List<DailyLog>> getMonthLogs(int year, int month) async {
    final repo = ref.read(dailyLogRepositoryProvider);
    return repo.getByMonth(year, month);
  }

  /// Returns today's date as YYYY-MM-DD string (the PK format).
  String _todayId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

/// Provider for today's daily log state.
final dailyLogProvider =
    AsyncNotifierProvider<DailyLogNotifier, DailyLog?>(() {
  return DailyLogNotifier();
});

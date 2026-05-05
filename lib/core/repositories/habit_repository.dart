import 'package:life_flow/core/database/database_helper.dart';
import 'package:life_flow/core/models/habit.dart';
import 'package:sqflite/sqflite.dart';

// =============================================================================
// HabitRepository — CRUD + query operations for Habit templates
// =============================================================================

class HabitRepository {
  final DatabaseHelper _dbHelper;

  HabitRepository(this._dbHelper);

  /// Insert a new habit.
  Future<void> insert(Habit habit) async {
    final db = await _dbHelper.database;
    await db.insert(
      'habits',
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all habits.
  Future<List<Habit>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('habits', orderBy: 'title ASC');
    return maps.map((m) => Habit.fromMap(m)).toList();
  }

  /// Get a single habit by ID.
  Future<Habit?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  /// Get habits that are active on a specific weekday (1=Mon .. 7=Sun).
  /// Daily habits always match. SpecificDays habits match if the weekday
  /// is contained in their active_days comma-separated list.
  Future<List<Habit>> getActiveForDay(int weekday) async {
    final allHabits = await getAll();
    return allHabits.where((h) => h.isActiveOn(weekday)).toList();
  }

  /// Update a habit.
  Future<void> update(Habit habit) async {
    final db = await _dbHelper.database;
    await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  /// Delete a habit by ID. Cascades to delete all associated executions.
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

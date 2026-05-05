import 'package:life_flow/core/database/database_helper.dart';
import 'package:life_flow/core/models/habit_execution.dart';
import 'package:sqflite/sqflite.dart';

class HabitExecutionRepository {
  final DatabaseHelper _dbHelper;
  HabitExecutionRepository(this._dbHelper);

  Future<void> insert(HabitExecution execution) async {
    final db = await _dbHelper.database;
    await db.insert('habit_executions', execution.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<HabitExecution?> getByHabitAndDate(String habitId, DateTime date) async {
    final db = await _dbHelper.database;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final maps = await db.query('habit_executions',
        where: 'habit_id = ? AND execution_date LIKE ?',
        whereArgs: [habitId, '$dateStr%']);
    if (maps.isEmpty) return null;
    return HabitExecution.fromMap(maps.first);
  }

  Future<List<HabitExecution>> getByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final maps = await db.query('habit_executions',
        where: 'execution_date LIKE ?', whereArgs: ['$dateStr%']);
    return maps.map((m) => HabitExecution.fromMap(m)).toList();
  }

  Future<List<HabitExecution>> getByDateRange(DateTime start, DateTime end, {String? habitId}) async {
    final db = await _dbHelper.database;
    String where = 'execution_date >= ? AND execution_date <= ?';
    List<dynamic> args = [start.toIso8601String(), end.toIso8601String()];
    if (habitId != null) { where += ' AND habit_id = ?'; args.add(habitId); }
    final maps = await db.query('habit_executions', where: where, whereArgs: args, orderBy: 'execution_date ASC');
    return maps.map((m) => HabitExecution.fromMap(m)).toList();
  }

  Future<int> getMonthlyCompletionCount(String habitId, int year, int month) async {
    final db = await _dbHelper.database;
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM habit_executions WHERE habit_id = ? AND execution_date LIKE ? AND is_completed = 1',
        [habitId, '$prefix%']);
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> update(HabitExecution execution) async {
    final db = await _dbHelper.database;
    await db.update('habit_executions', execution.toMap(), where: 'id = ?', whereArgs: [execution.id]);
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('habit_executions', where: 'id = ?', whereArgs: [id]);
  }
}

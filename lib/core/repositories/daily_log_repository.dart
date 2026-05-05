import 'package:life_flow/core/database/database_helper.dart';
import 'package:life_flow/core/models/daily_log.dart';
import 'package:sqflite/sqflite.dart';

// =============================================================================
// DailyLogRepository — CRUD + query operations for DailyLog
// =============================================================================

class DailyLogRepository {
  final DatabaseHelper _dbHelper;

  DailyLogRepository(this._dbHelper);

  /// Insert or replace a daily log (upsert by date-based PK).
  Future<void> insert(DailyLog log) async {
    final db = await _dbHelper.database;
    await db.insert(
      'daily_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get the log for a specific date (YYYY-MM-DD format).
  Future<DailyLog?> getByDate(String dateId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'daily_logs',
      where: 'id = ?',
      whereArgs: [dateId],
    );
    if (maps.isEmpty) return null;
    return DailyLog.fromMap(maps.first);
  }

  /// Get all logs for a given month (e.g., "2026-05" matches "2026-05-01", etc).
  Future<List<DailyLog>> getByMonth(int year, int month) async {
    final db = await _dbHelper.database;
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'daily_logs',
      where: 'id LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'id ASC',
    );
    return maps.map((m) => DailyLog.fromMap(m)).toList();
  }

  /// Get all daily logs, ordered by date descending.
  Future<List<DailyLog>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('daily_logs', orderBy: 'id DESC');
    return maps.map((m) => DailyLog.fromMap(m)).toList();
  }

  /// Update an existing daily log.
  Future<void> update(DailyLog log) async {
    final db = await _dbHelper.database;
    await db.update(
      'daily_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  /// Delete a daily log by its date ID.
  Future<void> delete(String dateId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'daily_logs',
      where: 'id = ?',
      whereArgs: [dateId],
    );
  }
}

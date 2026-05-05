import 'package:life_flow/core/database/database_helper.dart';
import 'package:life_flow/core/models/project_task.dart';
import 'package:sqflite/sqflite.dart';

// =============================================================================
// ProjectTaskRepository — CRUD + query operations for Kanban tasks
// Includes scheduled_date queries for the "Today Nexus" integration.
// =============================================================================

class ProjectTaskRepository {
  final DatabaseHelper _dbHelper;

  ProjectTaskRepository(this._dbHelper);

  /// Insert a new task.
  Future<void> insert(ProjectTask task) async {
    final db = await _dbHelper.database;
    await db.insert(
      'project_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all tasks, ordered by priority (high → low) then due date.
  Future<List<ProjectTask>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'project_tasks',
      orderBy: '''
        CASE priority
          WHEN 'high' THEN 0
          WHEN 'medium' THEN 1
          WHEN 'low' THEN 2
        END ASC,
        due_date ASC
      ''',
    );
    return maps.map((m) => ProjectTask.fromMap(m)).toList();
  }

  /// Get all tasks for a specific project.
  Future<List<ProjectTask>> getByProject(String projectId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'project_tasks',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: '''
        CASE priority
          WHEN 'high' THEN 0
          WHEN 'medium' THEN 1
          WHEN 'low' THEN 2
        END ASC
      ''',
    );
    return maps.map((m) => ProjectTask.fromMap(m)).toList();
  }

  /// Get tasks by status (for Kanban column filtering).
  Future<List<ProjectTask>> getByStatus(TaskStatus status) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'project_tasks',
      where: 'status = ?',
      whereArgs: [status.name],
    );
    return maps.map((m) => ProjectTask.fromMap(m)).toList();
  }

  /// Get tasks scheduled for a specific date.
  /// This is the core query that feeds the "Today Nexus" dashboard.
  Future<List<ProjectTask>> getScheduledForDate(DateTime date) async {
    final db = await _dbHelper.database;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'project_tasks',
      where: 'scheduled_date LIKE ? AND status != ?',
      whereArgs: ['$dateStr%', 'done'],
      orderBy: '''
        CASE priority
          WHEN 'high' THEN 0
          WHEN 'medium' THEN 1
          WHEN 'low' THEN 2
        END ASC
      ''',
    );
    return maps.map((m) => ProjectTask.fromMap(m)).toList();
  }

  /// Get tasks due today or overdue (not yet done).
  Future<List<ProjectTask>> getDueOrOverdue() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final todayEnd =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T23:59:59';
    final maps = await db.query(
      'project_tasks',
      where: 'due_date <= ? AND status != ?',
      whereArgs: [todayEnd, 'done'],
      orderBy: 'due_date ASC',
    );
    return maps.map((m) => ProjectTask.fromMap(m)).toList();
  }

  /// Update a task (e.g., status change on Kanban drag).
  Future<void> update(ProjectTask task) async {
    final db = await _dbHelper.database;
    await db.update(
      'project_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Delete a task by ID.
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'project_tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

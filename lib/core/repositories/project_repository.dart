import 'package:life_flow/core/database/database_helper.dart';
import 'package:life_flow/core/models/project.dart';
import 'package:sqflite/sqflite.dart';

// =============================================================================
// ProjectRepository — CRUD operations for Projects
// =============================================================================

class ProjectRepository {
  final DatabaseHelper _dbHelper;

  ProjectRepository(this._dbHelper);

  /// Insert a new project.
  Future<void> insert(Project project) async {
    final db = await _dbHelper.database;
    await db.insert(
      'projects',
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all projects, ordered by name.
  Future<List<Project>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('projects', orderBy: 'name ASC');
    return maps.map((m) => Project.fromMap(m)).toList();
  }

  /// Get a single project by ID.
  Future<Project?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Project.fromMap(maps.first);
  }

  /// Update a project.
  Future<void> update(Project project) async {
    final db = await _dbHelper.database;
    await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  /// Delete a project by ID. Cascades to delete all associated tasks.
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

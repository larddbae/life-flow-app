import 'package:life_flow/core/database/database_helper.dart';
import 'package:life_flow/core/models/tech_skill.dart';
import 'package:sqflite/sqflite.dart';

class TechSkillRepository {
  final DatabaseHelper _dbHelper;
  TechSkillRepository(this._dbHelper);

  Future<void> insert(TechSkill skill) async {
    final db = await _dbHelper.database;
    await db.insert('tech_skills', skill.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TechSkill>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('tech_skills', orderBy: 'name ASC');
    return maps.map((m) => TechSkill.fromMap(m)).toList();
  }

  Future<List<TechSkill>> getByStatus(SkillStatus status) async {
    final db = await _dbHelper.database;
    final maps = await db.query('tech_skills',
        where: 'status = ?', whereArgs: [status.name]);
    return maps.map((m) => TechSkill.fromMap(m)).toList();
  }

  Future<void> update(TechSkill skill) async {
    final db = await _dbHelper.database;
    await db.update('tech_skills', skill.toMap(),
        where: 'id = ?', whereArgs: [skill.id]);
  }

  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete('tech_skills', where: 'id = ?', whereArgs: [id]);
  }
}

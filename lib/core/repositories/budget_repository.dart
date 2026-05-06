import 'package:life_flow/core/database/database_helper.dart';
import 'package:life_flow/core/models/budget.dart';
import 'package:sqflite/sqflite.dart';

// =============================================================================
// BudgetRepository — CRUD for category budgets
// =============================================================================

class BudgetRepository {
  final DatabaseHelper _dbHelper;

  BudgetRepository(this._dbHelper);

  /// Insert or update a budget limit
  Future<void> updateBudget(Budget budget) async {
    final db = await _dbHelper.database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all budgets
  Future<List<Budget>> getAllBudgets() async {
    final db = await _dbHelper.database;
    final maps = await db.query('budgets');
    return maps.map((m) => Budget.fromMap(m)).toList();
  }

  /// Delete a budget category
  Future<void> deleteBudget(String category) async {
    final db = await _dbHelper.database;
    await db.delete(
      'budgets',
      where: 'category = ?',
      whereArgs: [category],
    );
  }
}

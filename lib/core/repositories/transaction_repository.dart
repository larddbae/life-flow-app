import 'package:life_flow/core/database/database_helper.dart';
import 'package:life_flow/core/models/transaction.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

// =============================================================================
// TransactionRepository — CRUD + query operations for financial transactions
// Includes special queries for wishlist funding calculations.
// =============================================================================

class TransactionRepository {
  final DatabaseHelper _dbHelper;

  TransactionRepository(this._dbHelper);

  /// Insert a new transaction.
  Future<void> insert(Transaction transaction) async {
    final db = await _dbHelper.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all transactions, ordered by date descending.
  Future<List<Transaction>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  /// Get transactions within a date range (inclusive).
  Future<List<Transaction>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  /// Get transactions for a specific category.
  Future<List<Transaction>> getByCategory(String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  /// Get all transactions allocated to a specific wishlist item.
  Future<List<Transaction>> getForWishlist(String wishlistId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'wishlist_id = ?',
      whereArgs: [wishlistId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  /// Get the total amount funded for a specific wishlist item.
  /// This powers the savings progress bar in the Finance module.
  Future<double> getTotalFundedForWishlist(String wishlistId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE wishlist_id = ?',
      [wishlistId],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// Get today's total expenses (for the dashboard "Daily Budget Remaining").
  Future<double> getTodayExpenses() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense' AND date LIKE ?",
      ['$dateStr%'],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// Get monthly spending by category for a given month.
  Future<Map<String, double>> getMonthlyCategoryTotals(
    int year,
    int month,
  ) async {
    final db = await _dbHelper.database;
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final result = await db.rawQuery(
      "SELECT category, SUM(amount) as total FROM transactions WHERE type = 'expense' AND date LIKE ? GROUP BY category",
      ['$prefix%'],
    );
    return {
      for (final row in result)
        row['category'] as String: (row['total'] as num).toDouble(),
    };
  }

  /// Delete a transaction by ID.
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

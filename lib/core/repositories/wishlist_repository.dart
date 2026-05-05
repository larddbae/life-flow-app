import 'package:life_flow/core/database/database_helper.dart';
import 'package:life_flow/core/models/wishlist.dart';
import 'package:sqflite/sqflite.dart';

// =============================================================================
// WishlistRepository — CRUD + query operations for Wishlist (Savings Goals)
// =============================================================================

class WishlistRepository {
  final DatabaseHelper _dbHelper;

  WishlistRepository(this._dbHelper);

  /// Insert a new wishlist item.
  Future<void> insert(Wishlist item) async {
    final db = await _dbHelper.database;
    await db.insert(
      'wishlists',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all wishlist items, ordered by creation date descending.
  Future<List<Wishlist>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('wishlists', orderBy: 'created_at DESC');
    return maps.map((m) => Wishlist.fromMap(m)).toList();
  }

  /// Get a single wishlist item by ID.
  Future<Wishlist?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'wishlists',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Wishlist.fromMap(maps.first);
  }

  /// Get only active (non-achieved) wishlist items.
  Future<List<Wishlist>> getActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'wishlists',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Wishlist.fromMap(m)).toList();
  }

  /// Update a wishlist item.
  Future<void> update(Wishlist item) async {
    final db = await _dbHelper.database;
    await db.update(
      'wishlists',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete a wishlist item by ID.
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'wishlists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

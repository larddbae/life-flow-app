import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// =============================================================================
// DatabaseHelper — Singleton SQLite database manager
// Creates all 8 tables from the PRD schema. Foreign keys are enforced.
// =============================================================================

class DatabaseHelper {
  static const String _databaseName = 'life_flow.db';
  static const int _databaseVersion = 2;

  // Singleton instance
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  /// Returns the database instance, creating it lazily on first access.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Enable foreign key support for referential integrity.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create all 8 tables matching the PRD schema exactly.
  Future<void> _onCreate(Database db, int version) async {
    // 1. DailyLog — Tracks daily energy and manual journal
    await db.execute('''
      CREATE TABLE daily_logs (
        id TEXT PRIMARY KEY,
        energy_level INTEGER NOT NULL CHECK(energy_level BETWEEN 1 AND 5),
        journal_notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Wishlist — Savings Goals
    await db.execute('''
      CREATE TABLE wishlists (
        id TEXT PRIMARY KEY,
        item_name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        url TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Transaction — Financial Tracking
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        wishlist_id TEXT,
        notes TEXT,
        FOREIGN KEY (wishlist_id) REFERENCES wishlists(id) ON DELETE SET NULL
      )
    ''');

    // 9. Budgets — User-defined category limits
    await db.execute('''
      CREATE TABLE budgets (
        category TEXT PRIMARY KEY,
        target_limit REAL NOT NULL
      )
    ''');
    // Seed initial default budgets
    await db.execute("INSERT INTO budgets (category, target_limit) VALUES ('Food', 500000.0)");
    await db.execute("INSERT INTO budgets (category, target_limit) VALUES ('Transport', 500000.0)");
    await db.execute("INSERT INTO budgets (category, target_limit) VALUES ('Tech', 1000000.0)");

    // 4. Project — Groups tasks together
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_code TEXT NOT NULL
      )
    ''');

    // 5. ProjectTask — Kanban Tasks
    await db.execute('''
      CREATE TABLE project_tasks (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        title TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'toDo',
        due_date TEXT,
        scheduled_date TEXT,
        priority TEXT NOT NULL DEFAULT 'medium',
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    // 6. Habit — Routine Templates
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        frequency_type TEXT NOT NULL DEFAULT 'daily',
        active_days TEXT NOT NULL DEFAULT '',
        module_type TEXT NOT NULL DEFAULT 'boolean',
        target_value INTEGER
      )
    ''');

    // 7. HabitExecution — Daily habit logs
    await db.execute('''
      CREATE TABLE habit_executions (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        execution_date TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        recorded_value INTEGER,
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');

    // 8. TechSkill — Learning Radar
    await db.execute('''
      CREATE TABLE tech_skills (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'planned',
        resource_url TEXT
      )
    ''');

    // ── Indexes for common queries ──────────────────────────────────────────
    await db.execute(
        'CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute(
        'CREATE INDEX idx_transactions_wishlist ON transactions(wishlist_id)');
    await db.execute(
        'CREATE INDEX idx_project_tasks_project ON project_tasks(project_id)');
    await db.execute(
        'CREATE INDEX idx_project_tasks_scheduled ON project_tasks(scheduled_date)');
    await db.execute(
        'CREATE INDEX idx_habit_executions_habit ON habit_executions(habit_id)');
    await db.execute(
        'CREATE INDEX idx_habit_executions_date ON habit_executions(execution_date)');
  }

  /// Handle database schema migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 1. Add notes to transactions
      await db.execute('ALTER TABLE transactions ADD COLUMN notes TEXT');
      
      // 2. Create budgets table
      await db.execute('''
        CREATE TABLE budgets (
          category TEXT PRIMARY KEY,
          target_limit REAL NOT NULL
        )
      ''');
      // Seed default budgets for existing users
      await db.execute("INSERT INTO budgets (category, target_limit) VALUES ('Food', 500000.0)");
      await db.execute("INSERT INTO budgets (category, target_limit) VALUES ('Transport', 500000.0)");
      await db.execute("INSERT INTO budgets (category, target_limit) VALUES ('Tech', 1000000.0)");
    }
  }

  /// Close the database connection. Call on app teardown if needed.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/database/database_helper.dart';
import 'package:life_flow/core/repositories/budget_repository.dart';
import 'package:life_flow/core/repositories/daily_log_repository.dart';
import 'package:life_flow/core/repositories/habit_execution_repository.dart';
import 'package:life_flow/core/repositories/habit_repository.dart';
import 'package:life_flow/core/repositories/project_repository.dart';
import 'package:life_flow/core/repositories/project_task_repository.dart';
import 'package:life_flow/core/repositories/tech_skill_repository.dart';
import 'package:life_flow/core/repositories/transaction_repository.dart';
import 'package:life_flow/core/repositories/wishlist_repository.dart';

// =============================================================================
// Database & Repository Providers — Dependency Injection Layer
// All repositories are lazily created and share the singleton DatabaseHelper.
// =============================================================================

/// Provides the singleton [DatabaseHelper] instance.
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// Provides [DailyLogRepository] backed by the shared database.
final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  return DailyLogRepository(ref.watch(databaseProvider));
});

/// Provides [WishlistRepository] backed by the shared database.
final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.watch(databaseProvider));
});

/// Provides [TransactionRepository] backed by the shared database.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

/// Provides [ProjectRepository] backed by the shared database.
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(databaseProvider));
});

/// Provides [ProjectTaskRepository] backed by the shared database.
final projectTaskRepositoryProvider = Provider<ProjectTaskRepository>((ref) {
  return ProjectTaskRepository(ref.watch(databaseProvider));
});

/// Provides [HabitRepository] backed by the shared database.
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(ref.watch(databaseProvider));
});

/// Provides [HabitExecutionRepository] backed by the shared database.
final habitExecutionRepositoryProvider =
    Provider<HabitExecutionRepository>((ref) {
  return HabitExecutionRepository(ref.watch(databaseProvider));
});

/// Provides [TechSkillRepository] backed by the shared database.
final techSkillRepositoryProvider = Provider<TechSkillRepository>((ref) {
  return TechSkillRepository(ref.watch(databaseProvider));
});

/// Provides [BudgetRepository] backed by the shared database.
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(databaseProvider));
});

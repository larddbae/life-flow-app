import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/budget.dart';
import 'package:life_flow/core/providers/database_provider.dart';

// =============================================================================
// BudgetNotifier — Manages user-defined category limits
// =============================================================================

class BudgetNotifier extends AsyncNotifier<Map<String, double>> {
  @override
  Future<Map<String, double>> build() async {
    return _loadBudgets();
  }

  Future<Map<String, double>> _loadBudgets() async {
    final repo = ref.read(budgetRepositoryProvider);
    final budgets = await repo.getAllBudgets();
    return {for (var b in budgets) b.category: b.targetLimit};
  }

  /// Update the target limit for a specific category.
  Future<void> updateBudgetLimit(String category, double newLimit) async {
    final repo = ref.read(budgetRepositoryProvider);
    final budget = Budget(category: category, targetLimit: newLimit);
    await repo.updateBudget(budget);
    
    // Refresh state
    state = AsyncData(await _loadBudgets());
  }

  /// Delete a budget category.
  Future<void> deleteBudgetCategory(String category) async {
    final repo = ref.read(budgetRepositoryProvider);
    await repo.deleteBudget(category);
    
    // Refresh state
    state = AsyncData(await _loadBudgets());
  }
}

/// Provider for budget limits.
final budgetProvider =
    AsyncNotifierProvider<BudgetNotifier, Map<String, double>>(() {
  return BudgetNotifier();
});

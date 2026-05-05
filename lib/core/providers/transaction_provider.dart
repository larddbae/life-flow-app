import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/transaction.dart';
import 'package:life_flow/core/providers/database_provider.dart';
import 'package:life_flow/core/providers/wishlist_provider.dart';
import 'package:uuid/uuid.dart';

// =============================================================================
// TransactionState — Holds transactions + computed financial summaries.
// =============================================================================

class TransactionState {
  final List<Transaction> transactions;
  final double todayExpenses;
  final double monthlyIncome;
  final double monthlyExpenses;

  const TransactionState({
    this.transactions = const [],
    this.todayExpenses = 0,
    this.monthlyIncome = 0,
    this.monthlyExpenses = 0,
  });

  /// Net balance for the current month.
  double get monthlyBalance => monthlyIncome - monthlyExpenses;

  TransactionState copyWith({
    List<Transaction>? transactions,
    double? todayExpenses,
    double? monthlyIncome,
    double? monthlyExpenses,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      todayExpenses: todayExpenses ?? this.todayExpenses,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
    );
  }
}

// =============================================================================
// TransactionNotifier — Manages income/expense tracking with summaries.
// =============================================================================

class TransactionNotifier extends AsyncNotifier<TransactionState> {
  @override
  Future<TransactionState> build() async {
    return _loadState();
  }

  Future<TransactionState> _loadState() async {
    final repo = ref.read(transactionRepositoryProvider);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final monthlyTxns = await repo.getByDateRange(monthStart, monthEnd);
    final todayExp = await repo.getTodayExpenses();

    double income = 0;
    double expenses = 0;
    for (final txn in monthlyTxns) {
      if (txn.type == TransactionType.income) {
        income += txn.amount;
      } else {
        expenses += txn.amount;
      }
    }

    return TransactionState(
      transactions: monthlyTxns,
      todayExpenses: todayExp,
      monthlyIncome: income,
      monthlyExpenses: expenses,
    );
  }

  /// Add a new transaction (income or expense).
  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required String category,
    DateTime? date,
    String? wishlistId,
  }) async {
    final repo = ref.read(transactionRepositoryProvider);
    final txn = Transaction(
      id: const Uuid().v4(),
      amount: amount,
      type: type,
      category: category,
      date: date ?? DateTime.now(),
      wishlistId: wishlistId,
    );
    await repo.insert(txn);

    // Refresh own state
    state = AsyncData(await _loadState());

    // If this funds a wishlist, refresh the wishlist provider too
    if (wishlistId != null) {
      ref.read(wishlistProvider.notifier).refresh();
    }
  }

  /// Delete a transaction.
  Future<void> deleteTransaction(String id) async {
    final repo = ref.read(transactionRepositoryProvider);

    // Check if it was a wishlist funding transaction
    final current = state.valueOrNull;
    final txn = current?.transactions.where((t) => t.id == id).firstOrNull;
    final hadWishlist = txn?.wishlistId;

    await repo.delete(id);
    state = AsyncData(await _loadState());

    // Refresh wishlist if the deleted txn was funding one
    if (hadWishlist != null) {
      ref.read(wishlistProvider.notifier).refresh();
    }
  }

  /// Get category breakdown for a specific month (for Reflection).
  Future<Map<String, double>> getCategoryBreakdown(
      int year, int month) async {
    final repo = ref.read(transactionRepositoryProvider);
    return repo.getMonthlyCategoryTotals(year, month);
  }

  /// Force a full refresh.
  Future<void> refresh() async {
    state = AsyncData(await _loadState());
  }
}

/// Provider for financial transaction state with computed summaries.
final transactionProvider =
    AsyncNotifierProvider<TransactionNotifier, TransactionState>(() {
  return TransactionNotifier();
});

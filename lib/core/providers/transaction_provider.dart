import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/transaction.dart';
import 'package:life_flow/core/providers/database_provider.dart';
import 'package:life_flow/core/providers/wishlist_provider.dart';
import 'package:uuid/uuid.dart';

// =============================================================================
// TransactionState — Holds transactions + computed financial summaries.
// =============================================================================

class TransactionState {
  final List<Transaction> transactions; // Monthly summaries mapping (if needed)
  final double todayExpenses;
  final double monthlyIncome;
  final double monthlyExpenses;
  
  // Paginated recent transactions
  final List<Transaction> recentTransactions;
  final bool hasMoreTransactions;
  final String currentFilter;

  const TransactionState({
    this.transactions = const [],
    this.todayExpenses = 0,
    this.monthlyIncome = 0,
    this.monthlyExpenses = 0,
    this.recentTransactions = const [],
    this.hasMoreTransactions = true,
    this.currentFilter = 'All',
  });

  /// Net balance for the current month.
  double get monthlyBalance => monthlyIncome - monthlyExpenses;

  TransactionState copyWith({
    List<Transaction>? transactions,
    double? todayExpenses,
    double? monthlyIncome,
    double? monthlyExpenses,
    List<Transaction>? recentTransactions,
    bool? hasMoreTransactions,
    String? currentFilter,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      todayExpenses: todayExpenses ?? this.todayExpenses,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      hasMoreTransactions: hasMoreTransactions ?? this.hasMoreTransactions,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

// =============================================================================
// TransactionNotifier — Manages income/expense tracking with summaries.
// =============================================================================

class TransactionNotifier extends AsyncNotifier<TransactionState> {
  static const int _pageSize = 10;
  int _currentPage = 0;

  @override
  Future<TransactionState> build() async {
    return _loadState();
  }

  Future<TransactionState> _loadState({
    String filter = 'All',
    bool isPagination = false,
  }) async {
    final repo = ref.read(transactionRepositoryProvider);
    
    // Load monthly summaries
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

    // Load paginated list
    final offset = _currentPage * _pageSize;
    final paginatedTxns = await repo.getPaginated(_pageSize, offset, filter: filter);
    final hasMore = paginatedTxns.length == _pageSize;

    List<Transaction> updatedRecent = [];
    if (isPagination) {
      final currentRecent = state.valueOrNull?.recentTransactions ?? [];
      updatedRecent = [...currentRecent, ...paginatedTxns];
    } else {
      updatedRecent = paginatedTxns;
    }

    return TransactionState(
      transactions: monthlyTxns,
      todayExpenses: todayExp,
      monthlyIncome: income,
      monthlyExpenses: expenses,
      recentTransactions: updatedRecent,
      hasMoreTransactions: hasMore,
      currentFilter: filter,
    );
  }

  /// Add a new transaction (income or expense).
  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required String category,
    DateTime? date,
    String? wishlistId,
    String? notes,
  }) async {
    final repo = ref.read(transactionRepositoryProvider);
    final txn = Transaction(
      id: const Uuid().v4(),
      amount: amount,
      type: type,
      category: category,
      date: date ?? DateTime.now(),
      wishlistId: wishlistId,
      notes: notes,
    );
    await repo.insert(txn);

    // Refresh own state (resetting pagination so new item appears)
    _currentPage = 0;
    final filter = state.valueOrNull?.currentFilter ?? 'All';
    state = AsyncData(await _loadState(filter: filter));

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
    final txn = current?.transactions.where((t) => t.id == id).firstOrNull 
             ?? current?.recentTransactions.where((t) => t.id == id).firstOrNull;
    final hadWishlist = txn?.wishlistId;

    await repo.delete(id);
    
    // Refresh state
    _currentPage = 0;
    final filter = current?.currentFilter ?? 'All';
    state = AsyncData(await _loadState(filter: filter));

    // Refresh wishlist if the deleted txn was funding one
    if (hadWishlist != null) {
      ref.read(wishlistProvider.notifier).refresh();
    }
  }

  /// Change the filter and reload recent transactions.
  Future<void> setFilter(String filter) async {
    _currentPage = 0;
    state = AsyncData(await _loadState(filter: filter));
  }

  /// Load the next page of transactions.
  Future<void> loadMoreTransactions() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMoreTransactions) return;

    _currentPage++;
    state = AsyncData(await _loadState(
      filter: current.currentFilter,
      isPagination: true,
    ));
  }

  /// Get category breakdown for a specific month (for Reflection).
  Future<Map<String, double>> getCategoryBreakdown(
      int year, int month) async {
    final repo = ref.read(transactionRepositoryProvider);
    return repo.getMonthlyCategoryTotals(year, month);
  }

  /// Force a full refresh.
  Future<void> refresh() async {
    _currentPage = 0;
    final filter = state.valueOrNull?.currentFilter ?? 'All';
    state = AsyncData(await _loadState(filter: filter));
  }
}

/// Provider for financial transaction state with computed summaries.
final transactionProvider =
    AsyncNotifierProvider<TransactionNotifier, TransactionState>(() {
  return TransactionNotifier();
});

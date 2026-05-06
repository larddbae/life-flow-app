import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/transaction.dart';
import 'package:life_flow/core/providers/budget_provider.dart';
import 'package:life_flow/core/providers/transaction_provider.dart';
import 'package:life_flow/core/providers/wishlist_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';
import 'package:life_flow/features/finance/widgets/add_transaction_sheet.dart';
import 'package:life_flow/features/finance/widgets/add_wishlist_sheet.dart';
import 'package:life_flow/features/finance/widgets/fund_wishlist_sheet.dart';
import 'package:life_flow/features/finance/widgets/manage_budgets_sheet.dart';

// =============================================================================
// FinanceScreen — Income/Expense tracking + Wishlist savings goals (RESTORED UI)
// =============================================================================

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90), // Offset for CustomBottomNavBar
        child: GestureDetector(
          onTap: () => _showSheet(context, const AddTransactionSheet()),
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.accentIndigo,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Header Mobile / Title ──────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Finance', style: AppTextStyles.headlineXl),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Balance Overview Card ──────────────────────────────────
                      const _BalanceOverviewCard(),
                      const SizedBox(height: 32),

                      // ── Budget Allocation Section Header ───────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Monthly Budgets', style: AppTextStyles.headlineLg),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                            onPressed: () => _showSheet(context, const ManageBudgetsSheet()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _BudgetSection(),
                      const SizedBox(height: 32),

                      // ── Savings Goals Section ──────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Savings Goals', style: AppTextStyles.headlineLg),
                          GestureDetector(
                            onTap: () => _showSheet(context, const AddWishlistSheet()),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentIndigo.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, size: 20, color: AppColors.accentIndigo),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),

                // ── Wishlist Grid ────────────────────────────────────────────────
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: _WishlistGridSliver(),
                ),

                // ── Recent Transactions Header ───────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Text('Recent Transactions', style: AppTextStyles.headlineLg),
                  ),
                ),
                
                // ── Filter Chips ─────────────────────────────────────────────────
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _TransactionFilterChips(),
                  ),
                ),

                const SliverPadding(
                  padding: EdgeInsets.only(top: 16),
                  sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

                // ── Transaction List ─────────────────────────────────────────────
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: _TransactionListSliver(),
                ),

                // Bottom clearance for nav bar
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
      ),
    );
  }

  void _showSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => sheet,
    );
  }
}

// =============================================================================
// Balance Overview Card
// =============================================================================

class _BalanceOverviewCard extends ConsumerWidget {
  const _BalanceOverviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(transactionProvider);

    return txnAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Error loading data')),
      data: (state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border.all(color: AppColors.borderSubtle),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Balance',
                  style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(_fmt(state.monthlyBalance), style: AppTextStyles.headlineXl),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _BalanceStatTile(
                        icon: Icons.arrow_upward,
                        iconColor: AppColors.statusSuccess,
                        label: 'Income',
                        amount: _fmt(state.monthlyIncome),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _BalanceStatTile(
                        icon: Icons.arrow_downward,
                        iconColor: AppColors.statusDanger,
                        label: 'Expenses',
                        amount: _fmt(state.monthlyExpenses),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(double v) {
    final abs = v.abs().round();
    final formatted = abs.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return v < 0 ? '-Rp $formatted' : 'Rp $formatted';
  }
}

class _BalanceStatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String amount;

  const _BalanceStatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.labelCaps),
            Text(amount, style: AppTextStyles.bodySm),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Monthly Budgets
// =============================================================================

class _BudgetSection extends ConsumerWidget {
  const _BudgetSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionProvider).valueOrNull;
    final budgets = ref.watch(budgetProvider).valueOrNull ?? {};
    final txns = state?.transactions ?? [];

    double getSpent(String category) {
      return txns
          .where((t) => t.category.toLowerCase().contains(category.toLowerCase()) && t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
    }

    if (budgets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          'No budget categories yet.\nTap the gear icon to add one.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: budgets.entries.map((entry) {
        final cat = entry.key;
        final limit = entry.value;
        final spent = getSpent(cat);

        // Assign default icon/color dynamically
        IconData icon = Icons.account_balance_wallet;
        Color color = AppColors.accentIndigo;
        final catLower = cat.toLowerCase();

        if (catLower.contains('food') || catLower.contains('grocer')) {
          icon = Icons.restaurant;
          color = AppColors.accentIndigo;
        } else if (catLower.contains('transport') || catLower.contains('ride')) {
          icon = Icons.directions_car;
          color = AppColors.statusWarning;
        } else if (catLower.contains('tech') || catLower.contains('device')) {
          icon = Icons.devices;
          color = AppColors.statusDanger;
        } else if (catLower.contains('health')) {
          icon = Icons.favorite;
          color = AppColors.statusDanger;
        } else if (catLower.contains('entertainment') || catLower.contains('fun')) {
          icon = Icons.movie;
          color = AppColors.accentIndigo;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _BudgetCard(
            icon: icon,
            iconColor: color,
            category: cat,
            spent: spent,
            limit: limit,
          ),
        );
      }).toList(),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String category;
  final double spent;
  final double limit;

  const _BudgetCard({
    required this.icon,
    required this.iconColor,
    required this.category,
    required this.spent,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (spent / limit).clamp(0.0, 1.0);
    final isExceeded = spent > limit;
    final displayColor = isExceeded ? AppColors.statusDanger : iconColor;
    
    String formatK(double v) {
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
      return v.toStringAsFixed(0);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Text(category,
                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
              Text('Rp ${formatK(spent)} / ${formatK(limit)}',
                  style: AppTextStyles.metadata),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: displayColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Wishlist Grid
// =============================================================================

class _WishlistGridSliver extends ConsumerWidget {
  const _WishlistGridSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);

    return wishlistAsync.when(
      loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (items) {
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text('No savings goals yet. Tap + to create one.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ),
          );
        }

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              return _WishlistCard(
                item: item,
                onFund: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.surfaceCard,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => FundWishlistSheet(item: item),
                  );
                },
              );
            },
            childCount: items.length,
          ),
        );
      },
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final WishlistWithFunding item;
  final VoidCallback onFund;

  const _WishlistCard({required this.item, required this.onFund});

  @override
  Widget build(BuildContext context) {
    final pct = (item.progress * 100).clamp(0, 100).round();
    
    String formatK(double v) {
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
      return v.toStringAsFixed(0);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(item.wishlist.itemName,
                  style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('Rp ${formatK(item.wishlist.targetAmount)} Target',
                  style: AppTextStyles.metadata),
            ],
          ),
          
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: item.progress.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    backgroundColor: AppColors.borderSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentIndigo),
                  ),
                ),
                Text('$pct%', style: AppTextStyles.labelCaps.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),

          GestureDetector(
            onTap: onFund,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentIndigo,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text('Fund 💰',
                  style: AppTextStyles.labelCaps.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Transactions List
// =============================================================================

class _TransactionFilterChips extends ConsumerWidget {
  const _TransactionFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionProvider).valueOrNull?.currentFilter ?? 'All';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', 'Income', 'Expense', 'Savings'].map((f) {
          final isSelected = filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                ref.read(transactionProvider.notifier).setFilter(f);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentIndigo.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                  borderRadius: AppRadius.chipRadius,
                  border: Border.all(
                    color: isSelected ? AppColors.accentIndigo : AppColors.borderSubtle,
                  ),
                ),
                child: Text(
                  f,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isSelected ? AppColors.accentIndigo : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TransactionListSliver extends ConsumerWidget {
  const _TransactionListSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(transactionProvider);

    return txnAsync.when(
      loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (state) {
        if (state.recentTransactions.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                  'No transactions found.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildListDelegate([
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: List.generate(
                    state.recentTransactions.length,
                    (index) {
                      final txn = state.recentTransactions[index];
                      final isLast = index == state.recentTransactions.length - 1;
                      return _TransactionTile(
                        txn: txn,
                        isLast: isLast,
                        onDelete: () {
                          ref.read(transactionProvider.notifier).deleteTransaction(txn.id);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            if (state.hasMoreTransactions)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: () {
                    ref.read(transactionProvider.notifier).loadMoreTransactions();
                  },
                  child: Text('Load More', style: AppTextStyles.bodyMd.copyWith(color: AppColors.accentIndigo)),
                ),
              ),
          ]),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction txn;
  final bool isLast;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.txn,
    required this.isLast,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.type == TransactionType.income;
    final sign = isIncome ? '+' : '-';
    final amount = txn.amount.round().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    
    Color getCategoryColor(String cat) {
      final l = cat.toLowerCase();
      if (l.contains('food') || l.contains('grocer')) return AppColors.accentIndigo;
      if (l.contains('transport') || l.contains('ride') || l.contains('uber')) return AppColors.statusWarning;
      if (isIncome) return AppColors.statusSuccess;
      return AppColors.statusDanger;
    }
    
    final lineIndicatorColor = getCategoryColor(txn.category);

    return Dismissible(
      key: Key(txn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.statusDanger.withValues(alpha: 0.15),
        child: const Icon(Icons.delete_outline, color: AppColors.statusDanger),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: lineIndicatorColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(txn.category, style: AppTextStyles.bodySm.copyWith(color: AppColors.textPrimary)),
                            if (txn.notes != null && txn.notes!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                txn.notes!,
                                style: AppTextStyles.metadata.copyWith(fontStyle: FontStyle.italic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              '${txn.date.day}/${txn.date.month}/${txn.date.year}',
                              style: AppTextStyles.metadata,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$sign Rp $amount',
                          style: AppTextStyles.bodySm.copyWith(
                              color: isIncome ? AppColors.statusSuccess : AppColors.statusDanger,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

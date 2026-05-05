import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/transaction.dart';
import 'package:life_flow/core/providers/transaction_provider.dart';
import 'package:life_flow/core/providers/wishlist_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';
import 'package:life_flow/features/finance/widgets/add_transaction_sheet.dart';
import 'package:life_flow/features/finance/widgets/add_wishlist_sheet.dart';
import 'package:life_flow/features/finance/widgets/fund_wishlist_sheet.dart';
import 'package:life_flow/shared/widgets/section_label.dart';

// =============================================================================
// FinanceScreen — Income/Expense tracking + Wishlist savings goals (LIVE)
// =============================================================================

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Fixed header with FABs ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Finance', style: AppTextStyles.headlineXl),
                      ),
                      _ActionButton(
                        icon: Icons.add,
                        label: 'Transaction',
                        onTap: () => _showSheet(
                            context, const AddTransactionSheet()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Monthly Summary Card ───────────────────────────
                  const _MonthlySummaryCard(),
                  const SizedBox(height: 24),

                  // ── Wishlist Section Header ────────────────────────
                  Row(
                    children: [
                      const Expanded(child: SectionLabel(text: 'Savings Goals')),
                      _ActionButton(
                        icon: Icons.add,
                        label: 'Goal',
                        onTap: () => _showSheet(
                            context, const AddWishlistSheet()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Wishlist Items ─────────────────────────────────────────
          const _WishlistSliver(),

          // ── Recent Transactions Header ─────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: SectionLabel(text: 'Recent Transactions'),
            ),
          ),

          // ── Transaction List ───────────────────────────────────────
          const _TransactionSliver(),

          // Bottom clearance for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
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
// Monthly Summary Card — Shows income, expenses, net balance
// =============================================================================

class _MonthlySummaryCard extends ConsumerWidget {
  const _MonthlySummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(transactionProvider);

    return txnAsync.when(
      loading: () => _buildCard('...', '...', '...'),
      error: (e, _) => _buildCard('Error', 'Error', 'Error'),
      data: (state) {
        return _buildCard(
          _fmt(state.monthlyIncome),
          _fmt(state.monthlyExpenses),
          _fmt(state.monthlyBalance),
        );
      },
    );
  }

  Widget _buildCard(String income, String expenses, String balance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatTile('Income', income, AppColors.statusSuccess)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile('Expenses', expenses, AppColors.statusDanger)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net Balance', style: AppTextStyles.metadata),
              Text(balance, style: AppTextStyles.headlineLg),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    final abs = v.abs().round();
    final formatted = abs.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return v < 0 ? '-Rp $formatted' : 'Rp $formatted';
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.metadata),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// =============================================================================
// Wishlist Sliver — Savings goals with progress bars
// =============================================================================

class _WishlistSliver extends ConsumerWidget {
  const _WishlistSliver();

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text('No savings goals yet. Tap + Goal to create one.',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: _WishlistTile(
                  item: item,
                  onFund: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppColors.surfaceCard,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => FundWishlistSheet(item: item),
                    );
                  },
                ),
              );
            },
            childCount: items.length,
          ),
        );
      },
    );
  }
}

class _WishlistTile extends StatelessWidget {
  final WishlistWithFunding item;
  final VoidCallback onFund;

  const _WishlistTile({required this.item, required this.onFund});

  @override
  Widget build(BuildContext context) {
    final pct = (item.progress * 100).clamp(0, 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.wishlist.itemName,
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              GestureDetector(
                onTap: onFund,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withValues(alpha: 0.12),
                    borderRadius: AppRadius.chipRadius,
                    border: Border.all(
                        color: AppColors.statusSuccess.withValues(alpha: 0.3)),
                  ),
                  child: Text('Fund',
                      style: AppTextStyles.metadata.copyWith(
                          color: AppColors.statusSuccess,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: AppRadius.chipRadius,
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: item.progress.clamp(0, 1),
                backgroundColor: AppColors.surfaceVariant,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.tertiary),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('$pct% funded',
              style: AppTextStyles.metadata
                  .copyWith(color: AppColors.tertiary)),
        ],
      ),
    );
  }
}

// =============================================================================
// Transaction Sliver — Recent transaction list with swipe-to-delete
// =============================================================================

class _TransactionSliver extends ConsumerWidget {
  const _TransactionSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(transactionProvider);

    return txnAsync.when(
      loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (state) {
        if (state.transactions.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                    'No transactions yet. Tap + Transaction to add one.',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final txn = state.transactions[index];
              return _TransactionTile(txn: txn);
            },
            childCount: state.transactions.length,
          ),
        );
      },
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final Transaction txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = txn.type == TransactionType.income;
    final color = isIncome ? AppColors.statusSuccess : AppColors.statusDanger;
    final sign = isIncome ? '+' : '-';
    final amount = txn.amount.round().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Dismissible(
      key: Key(txn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.statusDanger.withValues(alpha: 0.15),
        child: const Icon(Icons.delete_outline, color: AppColors.statusDanger),
      ),
      onDismissed: (_) {
        ref.read(transactionProvider.notifier).deleteTransaction(txn.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(txn.category, style: AppTextStyles.bodySm
                        .copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      '${txn.date.day}/${txn.date.month}/${txn.date.year}',
                      style: AppTextStyles.metadata,
                    ),
                  ],
                ),
              ),
              Text('$sign Rp $amount',
                  style: AppTextStyles.bodyMd.copyWith(
                      color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Shared small action button
// =============================================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentIndigo.withValues(alpha: 0.12),
          borderRadius: AppRadius.chipRadius,
          border: Border.all(
              color: AppColors.accentIndigo.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.accentIndigo),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.metadata.copyWith(
                    color: AppColors.accentIndigo,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/transaction.dart';
import 'package:life_flow/core/providers/transaction_provider.dart';
import 'package:life_flow/core/providers/wishlist_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// FundWishlistSheet — Bottom sheet for allocating funds to a savings goal
// =============================================================================

class FundWishlistSheet extends ConsumerStatefulWidget {
  final WishlistWithFunding item;
  const FundWishlistSheet({super.key, required this.item});

  @override
  ConsumerState<FundWishlistSheet> createState() => _FundWishlistSheetState();
}

class _FundWishlistSheetState extends ConsumerState<FundWishlistSheet> {
  final _amountController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);

    await ref.read(transactionProvider.notifier).addTransaction(
          amount: amount,
          type: TransactionType.income,
          category: 'Savings',
          wishlistId: widget.item.wishlist.id,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        widget.item.wishlist.targetAmount - widget.item.fundedAmount;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Fund: ${widget.item.wishlist.itemName}',
              style: AppTextStyles.headlineLg),
          const SizedBox(height: 8),
          Text(
            'Remaining: Rp ${remaining.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            style: AppTextStyles.metadata.copyWith(color: AppColors.tertiary),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: 'Amount to fund (Rp)',
              hintStyle: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.textSecondary),
              filled: true, fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusSuccess,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Allocate Funds', style: AppTextStyles.bodyMd.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

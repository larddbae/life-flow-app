import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/transaction.dart';
import 'package:life_flow/core/providers/transaction_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// AddTransactionSheet — Bottom sheet for logging income/expense
// =============================================================================

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  bool _isSubmitting = false;

  static const _categories = [
    'Food',
    'Transport',
    'Tech',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    final category = _categoryController.text.trim();
    if (amountText.isEmpty || category.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);

    await ref.read(transactionProvider.notifier).addTransaction(
          amount: amount,
          type: _type,
          category: category,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ─────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Add Transaction', style: AppTextStyles.headlineLg),
          const SizedBox(height: 20),

          // ── Type Toggle ────────────────────────────────────────────
          Row(
            children: [
              _TypeChip(
                label: 'Expense',
                isSelected: _type == TransactionType.expense,
                color: AppColors.statusDanger,
                onTap: () =>
                    setState(() => _type = TransactionType.expense),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Income',
                isSelected: _type == TransactionType.income,
                color: AppColors.statusSuccess,
                onTap: () =>
                    setState(() => _type = TransactionType.income),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Amount ─────────────────────────────────────────────────
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyMd,
            decoration: _inputDecoration('Amount (Rp)'),
          ),
          const SizedBox(height: 12),

          // ── Category Chips ─────────────────────────────────────────
          Text('Category', style: AppTextStyles.metadata),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _categoryController.text == cat;
              return GestureDetector(
                onTap: () => setState(() => _categoryController.text = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentIndigo.withValues(alpha: 0.15)
                        : AppColors.surfaceVariant,
                    borderRadius: AppRadius.chipRadius,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentIndigo
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: AppTextStyles.bodySm.copyWith(
                      color: isSelected
                          ? AppColors.accentIndigo
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Submit Button ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Save Transaction', style: AppTextStyles.bodyMd
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceVariant,
          borderRadius: AppRadius.chipRadius,
          border: Border.all(
            color: isSelected ? color : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySm.copyWith(
            color: isSelected ? color : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

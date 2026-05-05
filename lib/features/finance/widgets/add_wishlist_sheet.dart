import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/providers/wishlist_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// AddWishlistSheet — Bottom sheet for creating a new savings goal
// =============================================================================

class AddWishlistSheet extends ConsumerStatefulWidget {
  const AddWishlistSheet({super.key});

  @override
  ConsumerState<AddWishlistSheet> createState() => _AddWishlistSheetState();
}

class _AddWishlistSheetState extends ConsumerState<AddWishlistSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();
    if (name.isEmpty || amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);

    final url = _urlController.text.trim();
    await ref.read(wishlistProvider.notifier).addWishlist(
          itemName: name,
          targetAmount: amount,
          url: url.isNotEmpty ? url : null,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
          Text('New Savings Goal', style: AppTextStyles.headlineLg),
          const SizedBox(height: 20),

          TextField(
            controller: _nameController,
            style: AppTextStyles.bodyMd,
            decoration: _inputDecoration('Item name (e.g., iPad Pro)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyMd,
            decoration: _inputDecoration('Target amount (Rp)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            style: AppTextStyles.bodyMd,
            decoration: _inputDecoration('Product URL (optional)'),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: AppColors.onTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Create Goal', style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onTertiary, fontWeight: FontWeight.w600)),
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
      filled: true, fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

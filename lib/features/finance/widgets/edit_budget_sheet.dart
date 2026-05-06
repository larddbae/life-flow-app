import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/providers/budget_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// EditBudgetSheet — Bottom sheet for editing monthly budget targets
// =============================================================================

class EditBudgetSheet extends ConsumerStatefulWidget {
  final String category;
  final double currentLimit;

  const EditBudgetSheet({
    super.key,
    required this.category,
    required this.currentLimit,
  });

  @override
  ConsumerState<EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends ConsumerState<EditBudgetSheet> {
  late final TextEditingController _limitController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.currentLimit.round().toString(),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _limitController.text.trim();
    if (text.isEmpty) return;

    final limit = double.tryParse(text);
    if (limit == null || limit <= 0) return;

    setState(() => _isSubmitting = true);

    await ref
        .read(budgetProvider.notifier)
        .updateBudgetLimit(widget.category, limit);

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
          Text('Edit ${widget.category} Budget',
              style: AppTextStyles.headlineLg),
          const SizedBox(height: 20),

          // ── Target Limit ───────────────────────────────────────────
          TextField(
            controller: _limitController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: 'Target Limit (Rp)',
              hintStyle: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
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
                  : Text('Save Budget',
                      style: AppTextStyles.bodyMd.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

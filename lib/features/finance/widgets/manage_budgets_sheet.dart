import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/providers/budget_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// ManageBudgetsSheet — Bottom sheet for full CRUD on monthly budgets
// =============================================================================

class ManageBudgetsSheet extends ConsumerStatefulWidget {
  const ManageBudgetsSheet({super.key});

  @override
  ConsumerState<ManageBudgetsSheet> createState() => _ManageBudgetsSheetState();
}

class _ManageBudgetsSheetState extends ConsumerState<ManageBudgetsSheet> {
  final _categoryController = TextEditingController();
  final _limitController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final cat = _categoryController.text.trim();
    final limitStr = _limitController.text.trim();

    if (cat.isEmpty || limitStr.isEmpty) return;
    
    final limit = double.tryParse(limitStr);
    if (limit == null || limit <= 0) return;

    setState(() => _isAdding = true);

    await ref.read(budgetProvider.notifier).updateBudgetLimit(cat, limit);

    if (mounted) {
      _categoryController.clear();
      _limitController.clear();
      setState(() => _isAdding = false);
    }
  }

  void _deleteCategory(String category) {
    ref.read(budgetProvider.notifier).deleteBudgetCategory(category);
  }

  Future<void> _showEditDialog(String category, double currentLimit) async {
    final editController = TextEditingController(text: currentLimit.round().toString());
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit $category', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
          content: TextField(
            controller: editController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: 'New Limit (Rp)',
              hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final newLimitStr = editController.text.trim();
                final newLimit = double.tryParse(newLimitStr);
                if (newLimit != null && newLimit > 0) {
                  await ref.read(budgetProvider.notifier).updateBudgetLimit(category, newLimit);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              child: Text('Save', style: AppTextStyles.bodySm.copyWith(color: AppColors.accentIndigo, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
    
    editController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetProvider);

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
          Text('Manage Budgets', style: AppTextStyles.headlineLg),
          const SizedBox(height: 20),

          // ── Current Categories List ────────────────────────────────
          budgetsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('Error loading budgets')),
            data: (budgets) {
              if (budgets.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text('No budget categories yet.',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: budgets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = budgets.entries.elementAt(index);
                    final cat = entry.key;
                    final limit = entry.value;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text('Limit: Rp ${limit.round()}', style: AppTextStyles.metadata),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                                onPressed: () => _showEditDialog(cat, limit),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.statusDanger, size: 20),
                                onPressed: () => _deleteCategory(cat),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 16),

          // ── Add New Category Form ──────────────────────────────────
          Text('Add New Category', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _categoryController,
                  style: AppTextStyles.bodyMd,
                  decoration: _inputDecoration('Category (e.g. Utilities)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyMd,
                  decoration: _inputDecoration('Limit (Rp)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Add Button ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isAdding ? null : _addCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: _isAdding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Add Category',
                      style: AppTextStyles.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

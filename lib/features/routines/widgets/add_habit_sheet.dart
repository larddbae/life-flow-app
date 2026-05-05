import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/habit.dart';
import 'package:life_flow/core/providers/habit_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// AddHabitSheet — Bottom sheet for creating a new habit template
// =============================================================================

class AddHabitSheet extends ConsumerStatefulWidget {
  const AddHabitSheet({super.key});

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  final _titleController = TextEditingController();
  FrequencyType _frequency = FrequencyType.daily;
  ModuleType _module = ModuleType.boolean;
  final _targetController = TextEditingController();
  final Set<int> _selectedDays = {};
  bool _isSubmitting = false;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    int? target;
    if (_module != ModuleType.boolean) {
      target = int.tryParse(_targetController.text.trim());
      if (target == null || target <= 0) return;
    }

    setState(() => _isSubmitting = true);

    await ref.read(habitProvider.notifier).addHabit(
          title: title,
          frequencyType: _frequency,
          activeDays: _selectedDays.toList()..sort(),
          moduleType: _module,
          targetValue: target,
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
      child: SingleChildScrollView(
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
            Text('New Habit', style: AppTextStyles.headlineLg),
            const SizedBox(height: 20),

            // ── Title ────────────────────────────────────────────────
            TextField(
              controller: _titleController,
              style: AppTextStyles.bodyMd,
              decoration: _inputDecoration('Habit name (e.g., Read 30 min)'),
            ),
            const SizedBox(height: 16),

            // ── Frequency ────────────────────────────────────────────
            Text('Frequency', style: AppTextStyles.metadata),
            const SizedBox(height: 8),
            Row(
              children: [
                _chip('Daily', _frequency == FrequencyType.daily,
                    () => setState(() => _frequency = FrequencyType.daily)),
                const SizedBox(width: 8),
                _chip('Specific Days', _frequency == FrequencyType.specificDays,
                    () => setState(() => _frequency = FrequencyType.specificDays)),
              ],
            ),

            // ── Day Selector (only for specific days) ────────────────
            if (_frequency == FrequencyType.specificDays) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final selected = _selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () => setState(() {
                      selected
                          ? _selectedDays.remove(day)
                          : _selectedDays.add(day);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36, height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? AppColors.accentIndigo
                            : AppColors.surfaceVariant,
                        border: Border.all(
                          color: selected
                              ? AppColors.accentIndigo
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        _dayLabels[i],
                        style: AppTextStyles.bodySm.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 16),

            // ── Module Type ──────────────────────────────────────────
            Text('Tracking Type', style: AppTextStyles.metadata),
            const SizedBox(height: 8),
            Row(
              children: [
                _chip('Check ✓', _module == ModuleType.boolean,
                    () => setState(() => _module = ModuleType.boolean)),
                const SizedBox(width: 8),
                _chip('Timer ⏱', _module == ModuleType.timer,
                    () => setState(() => _module = ModuleType.timer)),
                const SizedBox(width: 8),
                _chip('Counter #', _module == ModuleType.counter,
                    () => setState(() => _module = ModuleType.counter)),
              ],
            ),

            // ── Target Value (for timer/counter) ─────────────────────
            if (_module != ModuleType.boolean) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyMd,
                decoration: _inputDecoration(
                  _module == ModuleType.timer
                      ? 'Target minutes (e.g., 25)'
                      : 'Target count (e.g., 3)',
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Submit ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity, height: 48,
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
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Create Habit', style: AppTextStyles.bodyMd.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentIndigo.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: AppRadius.chipRadius,
          border: Border.all(
            color: selected ? AppColors.accentIndigo : AppColors.borderSubtle,
          ),
        ),
        child: Text(label,
            style: AppTextStyles.bodySm.copyWith(
              color: selected ? AppColors.accentIndigo : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
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

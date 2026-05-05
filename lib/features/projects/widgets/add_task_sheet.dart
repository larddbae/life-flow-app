import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/project_task.dart';
import 'package:life_flow/core/providers/project_task_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// AddTaskSheet — Bottom sheet for adding a task to a project
// =============================================================================

class AddTaskSheet extends ConsumerStatefulWidget {
  final String projectId;
  const AddTaskSheet({super.key, required this.projectId});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _titleController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSubmitting = true);

    await ref.read(projectTaskProvider.notifier).addTask(
          projectId: widget.projectId,
          title: title,
          priority: _priority,
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
          Text('New Task', style: AppTextStyles.headlineLg),
          const SizedBox(height: 20),

          TextField(
            controller: _titleController,
            style: AppTextStyles.bodyMd,
            decoration: _inputDecoration('Task description...'),
            autofocus: true,
          ),
          const SizedBox(height: 16),

          Text('Priority', style: AppTextStyles.metadata),
          const SizedBox(height: 8),
          Row(
            children: [
              _PriorityChip(
                label: 'High',
                color: AppColors.statusDanger,
                isSelected: _priority == TaskPriority.high,
                onTap: () => setState(() => _priority = TaskPriority.high),
              ),
              const SizedBox(width: 8),
              _PriorityChip(
                label: 'Med',
                color: AppColors.tertiary,
                isSelected: _priority == TaskPriority.medium,
                onTap: () => setState(() => _priority = TaskPriority.medium),
              ),
              const SizedBox(width: 8),
              _PriorityChip(
                label: 'Low',
                color: AppColors.statusSuccess,
                isSelected: _priority == TaskPriority.low,
                onTap: () => setState(() => _priority = TaskPriority.low),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Add Task', style: AppTextStyles.bodyMd.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
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

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label, required this.color,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

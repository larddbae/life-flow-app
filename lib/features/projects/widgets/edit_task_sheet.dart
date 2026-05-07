import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/project_task.dart';
import 'package:life_flow/core/providers/project_task_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// EditTaskSheet — Bottom sheet for editing an existing task
// =============================================================================

class EditTaskSheet extends ConsumerStatefulWidget {
  final ProjectTask task;
  const EditTaskSheet({super.key, required this.task});

  @override
  ConsumerState<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends ConsumerState<EditTaskSheet> {
  late TextEditingController _titleController;
  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime? _dueDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _priority = widget.task.priority;
    _status = widget.task.status;
    _dueDate = widget.task.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSubmitting = true);

    final updatedTask = widget.task.copyWith(
      title: title,
      priority: _priority,
      status: _status,
      dueDate: _dueDate,
    );

    await ref.read(projectTaskProvider.notifier).updateTask(updatedTask);

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    setState(() => _isSubmitting = true);
    await ref.read(projectTaskProvider.notifier).deleteTask(widget.task.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentIndigo,
              onPrimary: Colors.white,
              surface: AppColors.surfaceCard,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateText = 'No Due Date';
    if (_dueDate != null) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateText = '${months[_dueDate!.month - 1]} ${_dueDate!.day}, ${_dueDate!.year}';
    }

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
          Text('Edit Task', style: AppTextStyles.headlineLg),
          const SizedBox(height: 20),

          TextField(
            controller: _titleController,
            style: AppTextStyles.bodyMd,
            decoration: _inputDecoration('Task description...'),
            autofocus: true,
          ),
          const SizedBox(height: 16),

          Text('Status', style: AppTextStyles.metadata),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TaskStatus>(
                value: _status,
                isExpanded: true,
                dropdownColor: AppColors.surfaceCard,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary),
                onChanged: (TaskStatus? newValue) {
                  if (newValue != null) {
                    setState(() => _status = newValue);
                  }
                },
                items: TaskStatus.values.map<DropdownMenuItem<TaskStatus>>((TaskStatus value) {
                  final label = switch (value) {
                    TaskStatus.toDo => 'To-Do',
                    TaskStatus.inProgress => 'In Progress',
                    TaskStatus.blocked => 'Blocked',
                    TaskStatus.done => 'Done',
                  };
                  return DropdownMenuItem<TaskStatus>(
                    value: value,
                    child: Text(label),
                  );
                }).toList(),
              ),
            ),
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
          const SizedBox(height: 16),

          Text('Due Date', style: AppTextStyles.metadata),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(dateText, style: AppTextStyles.bodyMd.copyWith(
                    color: _dueDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                  )),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.calendar_month, color: AppColors.accentIndigo),
                ),
              ),
              if (_dueDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _dueDate = null),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
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
                  : Text('Update Task', style: AppTextStyles.bodyMd.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          
          // Delete Button
          SizedBox(
            width: double.infinity, height: 48,
            child: TextButton(
              onPressed: _isSubmitting ? null : _delete,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.statusDanger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: Text('Delete Task', style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.statusDanger, fontWeight: FontWeight.w600)),
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

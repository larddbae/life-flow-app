import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/habit.dart';
import 'package:life_flow/core/providers/habit_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// ManageHabitsSheet — Bottom sheet for viewing, editing, and deleting habits
// Modelled after ManageBudgetsSheet with full CRUD support.
// =============================================================================

class ManageHabitsSheet extends ConsumerStatefulWidget {
  const ManageHabitsSheet({super.key});

  @override
  ConsumerState<ManageHabitsSheet> createState() => _ManageHabitsSheetState();
}

class _ManageHabitsSheetState extends ConsumerState<ManageHabitsSheet> {
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void _deleteHabit(String id) {
    ref.read(habitProvider.notifier).deleteHabit(id);
  }

  Future<void> _showEditDialog(Habit habit) async {
    final titleController = TextEditingController(text: habit.title);
    final targetController =
        TextEditingController(text: habit.targetValue?.toString() ?? '');
    FrequencyType freq = habit.frequencyType;
    ModuleType module = habit.moduleType;
    Set<int> selectedDays = {...habit.activeDays};

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('Edit Habit',
                  style: AppTextStyles.bodyMd
                      .copyWith(fontWeight: FontWeight.w600)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──────────────────────────────────────────
                    TextField(
                      controller: titleController,
                      style: AppTextStyles.bodyMd,
                      decoration: _inputDecoration('Habit name'),
                    ),
                    const SizedBox(height: 16),

                    // ── Frequency ──────────────────────────────────────
                    Text('Frequency', style: AppTextStyles.metadata),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _dialogChip(
                            'Daily', freq == FrequencyType.daily, () {
                          setDialogState(
                              () => freq = FrequencyType.daily);
                        }),
                        const SizedBox(width: 8),
                        _dialogChip('Specific Days',
                            freq == FrequencyType.specificDays, () {
                          setDialogState(
                              () => freq = FrequencyType.specificDays);
                        }),
                      ],
                    ),

                    if (freq == FrequencyType.specificDays) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(7, (i) {
                          final day = i + 1;
                          final selected = selectedDays.contains(day);
                          return GestureDetector(
                            onTap: () => setDialogState(() {
                              selected
                                  ? selectedDays.remove(day)
                                  : selectedDays.add(day);
                            }),
                            child: Container(
                              width: 36,
                              height: 36,
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
                                _dayLabels[i][0],
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

                    // ── Module Type ────────────────────────────────────
                    Text('Tracking Type', style: AppTextStyles.metadata),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _dialogChip('Check ✓', module == ModuleType.boolean,
                            () {
                          setDialogState(() => module = ModuleType.boolean);
                        }),
                        _dialogChip('Timer ⏱', module == ModuleType.timer,
                            () {
                          setDialogState(() => module = ModuleType.timer);
                        }),
                        _dialogChip('Counter #', module == ModuleType.counter,
                            () {
                          setDialogState(() => module = ModuleType.counter);
                        }),
                      ],
                    ),

                    if (module != ModuleType.boolean) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: targetController,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyMd,
                        decoration: _inputDecoration(
                          module == ModuleType.timer
                              ? 'Target minutes'
                              : 'Target count',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    int? target;
                    if (module != ModuleType.boolean) {
                      target = int.tryParse(targetController.text.trim());
                    }

                    final updated = habit.copyWith(
                      title: title,
                      frequencyType: freq,
                      activeDays: selectedDays.toList()..sort(),
                      moduleType: module,
                      targetValue: target,
                    );
                    await ref
                        .read(habitProvider.notifier)
                        .updateHabit(updated);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text('Save',
                      style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.accentIndigo,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    targetController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(allHabitsProvider);

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
          Text('Manage Habits', style: AppTextStyles.headlineLg),
          const SizedBox(height: 4),
          Text('Edit or delete your master habit templates.',
              style: AppTextStyles.metadata),
          const SizedBox(height: 20),

          // ── Grouped Habits List ─────────────────────────────────────
          habitsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const Center(child: Text('Error loading habits')),
            data: (habits) {
              if (habits.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        const Text('📋', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 12),
                        Text('No habits created yet.',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Use the + button to add one.',
                            style: AppTextStyles.metadata),
                      ],
                    ),
                  ),
                );
              }

              // ── Build flat list of section-header (String) + Habit items ──
              final listItems = <Object>[];

              final daily = habits
                  .where((h) => h.frequencyType == FrequencyType.daily)
                  .toList();
              final specific = habits
                  .where((h) => h.frequencyType == FrequencyType.specificDays)
                  .toList();

              // "Daily" section
              if (daily.isNotEmpty) {
                listItems.add('Daily');
                listItems.addAll(daily);
              }

              // One section per weekday (1=Mon … 7=Sun)
              for (int wd = 1; wd <= 7; wd++) {
                final forDay =
                    specific.where((h) => h.activeDays.contains(wd)).toList();
                if (forDay.isNotEmpty) {
                  listItems.add(_dayLabels[wd - 1]); // full day name header
                  listItems.addAll(forDay);
                }
              }

              // Catch-all: specificDays habits with no days selected
              final orphans =
                  specific.where((h) => h.activeDays.isEmpty).toList();
              if (orphans.isNotEmpty) {
                listItems.add('Custom Days');
                listItems.addAll(orphans);
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 460),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: listItems.length,
                  itemBuilder: (context, index) {
                    final item = listItems[index];

                    // ── Section header ──────────────────────────────────
                    if (item is String) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : 20,
                          bottom: 8,
                        ),
                        child: Row(
                          children: [
                            Text(
                              item.toUpperCase(),
                              style: AppTextStyles.labelCaps.copyWith(
                                color: AppColors.accentIndigo,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.borderSubtle,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // ── Habit tile ────────────────────────────────────────
                    final habit = item as Habit;
                    String emoji = '💪';
                    if (habit.moduleType == ModuleType.counter) emoji = '📖';
                    if (habit.moduleType == ModuleType.timer) emoji = '🍅';

                    final scheduleStr =
                        habit.frequencyType == FrequencyType.daily
                            ? 'Daily'
                            : habit.activeDays.isEmpty
                                ? 'No days set'
                                : habit.activeDays
                                    .map((d) =>
                                        _dayLabels[d - 1].substring(0, 3))
                                    .join(', ');
                    final targetStr = habit.targetValue != null
                        ? ' · Target: ${habit.targetValue}'
                        : '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            // Emoji avatar
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceContainer,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 12),
                            // Title + schedule
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    habit.title,
                                    style: AppTextStyles.bodyMd.copyWith(
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$scheduleStr$targetStr',
                                    style: AppTextStyles.metadata,
                                  ),
                                ],
                              ),
                            ),
                            // Edit
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.textSecondary, size: 18),
                              onPressed: () => _showEditDialog(habit),
                            ),
                            // Delete
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.statusDanger, size: 18),
                              onPressed: () => _deleteHabit(habit.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dialogChip(String label, bool selected, VoidCallback onTap) {
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
              color: selected
                  ? AppColors.accentIndigo
                  : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
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

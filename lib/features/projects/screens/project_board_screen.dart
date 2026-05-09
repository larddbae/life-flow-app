import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/project.dart';
import 'package:life_flow/core/models/project_task.dart';
import 'package:life_flow/core/providers/project_provider.dart';
import 'package:life_flow/core/providers/project_task_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';
import 'package:life_flow/features/projects/widgets/add_project_sheet.dart';
import 'package:life_flow/features/projects/widgets/add_task_sheet.dart';
import 'package:life_flow/features/projects/widgets/edit_task_sheet.dart';

// =============================================================================
// ProjectBoardScreen — Kanban view of projects and tasks (RESTORED UI)
// =============================================================================

class ProjectBoardScreen extends ConsumerStatefulWidget {
  const ProjectBoardScreen({super.key});

  @override
  ConsumerState<ProjectBoardScreen> createState() => _ProjectBoardScreenState();
}

class _ProjectBoardScreenState extends ConsumerState<ProjectBoardScreen> {
  String? _selectedProjectId;

  Color _hexToColor(String hex) {
    try {
      var hexColor = hex.replaceAll('#', '');
      if (hexColor.length == 6) hexColor = 'FF$hexColor';
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return AppColors.accentIndigo;
    }
  }

  Future<void> _pickDateFilter() async {
    final currentFilter = ref.read(taskDateFilterProvider);
    final date = await showDatePicker(
      context: context,
      initialDate: currentFilter ?? DateTime.now(),
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
      ref.read(taskDateFilterProvider.notifier).state = date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectProvider);
    final tasksByProject = ref.watch(tasksByProjectProvider);
    final dateFilter = ref.watch(taskDateFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90), // Offset for CustomBottomNavBar
        child: GestureDetector(
          onTap: () {
            if (_selectedProjectId != null) {
              _showSheet(context, AddTaskSheet(projectId: _selectedProjectId!));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please select a specific project filter to add a task.', style: AppTextStyles.bodySm),
                  backgroundColor: AppColors.surfaceContainerHighest,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.accentIndigo,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Project Board', style: AppTextStyles.headlineXl),
                  ),
                  _ActionButton(
                    icon: Icons.create_new_folder_outlined,
                    label: 'Project',
                    onTap: () => _showSheet(context, const AddProjectSheet()),
                  ),
                ],
              ),
            ),

            // ── Filter Pills ─────────────────────────────────────────────────
            projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('Error loading projects')),
              data: (projects) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _FilterPill(
                        title: 'All',
                        isSelected: _selectedProjectId == null,
                        onTap: () => setState(() => _selectedProjectId = null),
                      ),
                      const SizedBox(width: 8),
                      ...projects.map((p) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterPill(
                          title: p.name,
                          color: _hexToColor(p.colorCode),
                          isSelected: _selectedProjectId == p.id,
                          onTap: () => setState(() => _selectedProjectId = p.id),
                        ),
                      )),
                    ],
                  ),
                );
              },
            ),

            // ── Date Navigator Bar ────────────────────────────────────────────
            _DateNavigatorBar(
              dateFilter: dateFilter,
              onPrevDay: () {
                final current = ref.read(taskDateFilterProvider) ?? DateTime.now();
                ref.read(taskDateFilterProvider.notifier).state =
                    current.subtract(const Duration(days: 1));
              },
              onNextDay: () {
                final current = ref.read(taskDateFilterProvider) ?? DateTime.now();
                ref.read(taskDateFilterProvider.notifier).state =
                    current.add(const Duration(days: 1));
              },
              onTapCenter: _pickDateFilter,
            ),

            const SizedBox(height: 24),

            // ── Kanban Board Area ──────────────────────────────────────────
            Expanded(
              child: projectsAsync.maybeWhen(
                data: (projects) {
                  List<ProjectTask> allTasks = [];
                  if (_selectedProjectId == null) {
                    for (var list in tasksByProject.values) {
                      allTasks.addAll(list);
                    }
                  } else {
                    allTasks = tasksByProject[_selectedProjectId] ?? [];
                  }

                  if (dateFilter != null) {
                    allTasks = allTasks.where((t) =>
                        t.dueDate != null &&
                        t.dueDate!.year == dateFilter.year &&
                        t.dueDate!.month == dateFilter.month &&
                        t.dueDate!.day == dateFilter.day).toList();
                  }

                  final Map<String, Project> projectMap = {
                    for (var p in projects) p.id: p
                  };

                  final todoTasks = allTasks.where((t) => t.status == TaskStatus.toDo).toList();
                  final inProgressTasks = allTasks.where((t) => t.status == TaskStatus.inProgress).toList();
                  final blockedTasks = allTasks.where((t) => t.status == TaskStatus.blocked).toList();
                  final doneTasks = allTasks.where((t) => t.status == TaskStatus.done).toList();

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _KanbanColumn(title: 'TO-DO', tasks: todoTasks, status: TaskStatus.toDo, projectMap: projectMap),
                      const SizedBox(width: 16),
                      _KanbanColumn(title: 'IN PROGRESS', tasks: inProgressTasks, status: TaskStatus.inProgress, projectMap: projectMap),
                      const SizedBox(width: 16),
                      _KanbanColumn(title: 'BLOCKED', tasks: blockedTasks, status: TaskStatus.blocked, projectMap: projectMap),
                      const SizedBox(width: 16),
                      _KanbanColumn(title: 'DONE', tasks: doneTasks, status: TaskStatus.done, projectMap: projectMap),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            
            const SizedBox(height: 120), // Bottom navbar clearance
          ],
        ),
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
// Horizontal Filter Pill
// =============================================================================

class _FilterPill extends StatelessWidget {
  final String title;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.title,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentIndigo : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.accentIndigo : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: AppTextStyles.bodySm.copyWith(
                color: isSelected ? AppColors.onPrimaryContainer : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Kanban Column
// =============================================================================

class _KanbanColumn extends StatelessWidget {
  final String title;
  final List<ProjectTask> tasks;
  final TaskStatus status;
  final Map<String, Project> projectMap;

  const _KanbanColumn({
    required this.title,
    required this.tasks,
    required this.status,
    required this.projectMap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.85;
    final columnWidth = width > 320.0 ? 320.0 : width;

    return SizedBox(
      width: columnWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.labelCaps.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text('${tasks.length}', style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: tasks.isEmpty ? 1 : tasks.length,
              itemBuilder: (context, index) {
                if (tasks.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderSubtle, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Drop tasks here',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                  );
                }

                final task = tasks[index];
                final project = projectMap[task.projectId];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TaskCard(task: task, project: project),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Task Card
// =============================================================================

class _TaskCard extends ConsumerWidget {
  final ProjectTask task;
  final Project? project;

  const _TaskCard({required this.task, required this.project});

  Color _hexToColor(String hex) {
    try {
      var hexColor = hex.replaceAll('#', '');
      if (hexColor.length == 6) hexColor = 'FF$hexColor';
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return AppColors.accentIndigo;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityLabel = switch (task.priority) {
      TaskPriority.high => 'High',
      TaskPriority.medium => 'Medium',
      TaskPriority.low => 'Low',
    };
    final priorityColor = switch (task.priority) {
      TaskPriority.high => AppColors.statusDanger,
      TaskPriority.medium => AppColors.statusWarning,
      TaskPriority.low => AppColors.statusSuccess,
    };

    final isDone = task.status == TaskStatus.done;
    final isBlocked = task.status == TaskStatus.blocked;
    
    final projectColor = project != null ? _hexToColor(project!.colorCode) : AppColors.accentIndigo;

    double opacity = 1.0;
    if (isBlocked) opacity = 0.7;
    if (isDone) opacity = 0.5;

    String dateText = 'No Due Date';
    if (task.dueDate != null) {
      final now = DateTime.now();
      if (task.dueDate!.year == now.year && task.dueDate!.month == now.month && task.dueDate!.day == now.day) {
        dateText = 'Due Today';
      } else {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        dateText = 'Due ${months[task.dueDate!.month - 1]} ${task.dueDate!.day}';
      }
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surfaceCard,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => EditTaskSheet(task: task),
        );
      },
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top border strip indicating project
            Container(height: 4, width: double.infinity, color: projectColor),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with edit icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.textPrimary,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Badges
                  Row(
                    children: [
                      if (task.dueDate != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            border: Border.all(color: AppColors.borderSubtle),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(dateText, style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.2),
                          border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(priorityLabel, style: AppTextStyles.metadata.copyWith(color: priorityColor)),
                      ),
                      const Spacer(),
                      
                      // Move status pill
                      GestureDetector(
                        onTap: () {
                          final nextStatus = switch (task.status) {
                            TaskStatus.toDo => TaskStatus.inProgress,
                            TaskStatus.inProgress => TaskStatus.done,
                            TaskStatus.done => TaskStatus.toDo,
                            TaskStatus.blocked => TaskStatus.toDo,
                          };
                          ref.read(projectTaskProvider.notifier).updateStatus(task.id, nextStatus);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('Move ➔', style: AppTextStyles.metadata.copyWith(fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

// =============================================================================
// Date Navigator Bar
// =============================================================================

class _DateNavigatorBar extends StatelessWidget {
  final DateTime? dateFilter;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final VoidCallback onTapCenter;

  const _DateNavigatorBar({
    required this.dateFilter,
    required this.onPrevDay,
    required this.onNextDay,
    required this.onTapCenter,
  });

  bool get _isToday {
    if (dateFilter == null) return false;
    final now = DateTime.now();
    return dateFilter!.year == now.year &&
        dateFilter!.month == now.month &&
        dateFilter!.day == now.day;
  }

  String get _formattedDate {
    if (dateFilter == null) {
      final now = DateTime.now();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return '${days[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}';
    }
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[dateFilter!.weekday % 7]}, ${months[dateFilter!.month - 1]} ${dateFilter!.day}';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDate = dateFilter ?? DateTime.now();
    final prevDay = effectiveDate.subtract(const Duration(days: 1));
    final nextDay = effectiveDate.add(const Duration(days: 1));

    final monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final prevLabel = '${monthsShort[prevDay.month - 1]} ${prevDay.day}';
    final nextLabel = '${monthsShort[nextDay.month - 1]} ${nextDay.day}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Left: Previous day ──────────────────────────────────────
          GestureDetector(
            onTap: onPrevDay,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 2),
                  Text(
                    prevLabel,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // ── Center: Date pill ───────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: onTapCenter,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _isToday
                        ? AppColors.accentIndigo.withValues(alpha: 0.5)
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isToday) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentIndigo,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'TODAY',
                          style: AppTextStyles.metadata.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _formattedDate,
                      style: AppTextStyles.bodySm.copyWith(
                        color: _isToday ? AppColors.accentIndigo : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 14,
                      color: _isToday ? AppColors.accentIndigo : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Right: Next day ─────────────────────────────────────────
          GestureDetector(
            onTap: onNextDay,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nextLabel,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared Action Button
// =============================================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentIndigo.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.accentIndigo),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.metadata.copyWith(color: AppColors.accentIndigo, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/project.dart';
import 'package:life_flow/core/models/project_task.dart';
import 'package:life_flow/core/providers/project_provider.dart';
import 'package:life_flow/core/providers/project_task_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';
import 'package:life_flow/features/projects/widgets/add_project_sheet.dart';
import 'package:life_flow/features/projects/widgets/add_task_sheet.dart';

// =============================================================================
// ProjectBoardScreen — Kanban view of projects and tasks (LIVE)
// =============================================================================

class ProjectBoardScreen extends ConsumerWidget {
  const ProjectBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Text('Board', style: AppTextStyles.headlineXl),
                ),
                _ActionButton(
                  icon: Icons.create_new_folder_outlined,
                  label: 'Project',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.surfaceCard,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => const AddProjectSheet(),
                  ),
                ),
              ],
            ),
          ),

          // ── Horizontal PageView of Projects ────────────────────────
          Expanded(
            child: projectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('Error loading projects')),
              data: (projects) {
                if (projects.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.view_kanban_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text('No active projects', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }

                return PageView.builder(
                  controller: PageController(viewportFraction: 0.88),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _ProjectBoardContainer(project: projects[index]),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 120), // nav bar clearance
        ],
      ),
    );
  }
}

// =============================================================================
// Project Board Container — A single project card containing its tasks
// =============================================================================

class _ProjectBoardContainer extends ConsumerWidget {
  final Project project;
  const _ProjectBoardContainer({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksByProject = ref.watch(tasksByProjectProvider);
    final tasks = tasksByProject[project.id] ?? [];

    final todo = tasks.where((t) => t.status == TaskStatus.toDo).toList();
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final done = tasks.where((t) => t.status == TaskStatus.done).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Container Header ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.name, style: AppTextStyles.headlineLg),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.accentIndigo),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.surfaceCard,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => AddTaskSheet(projectId: project.id),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.statusDanger, size: 20),
                  onPressed: () => ref.read(projectProvider.notifier).deleteProject(project.id),
                ),
              ],
            ),
          ),

          // ── Task Lists (Kanban columns mapped vertically) ──────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TaskSection(title: 'To Do', tasks: todo, status: TaskStatus.toDo),
                const SizedBox(height: 20),
                _TaskSection(title: 'In Progress', tasks: inProgress, status: TaskStatus.inProgress),
                const SizedBox(height: 20),
                _TaskSection(title: 'Done', tasks: done, status: TaskStatus.done),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSection extends ConsumerWidget {
  final String title;
  final List<ProjectTask> tasks;
  final TaskStatus status;

  const _TaskSection({required this.title, required this.tasks, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTextStyles.metadata),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.chipRadius,
              ),
              child: Text('${tasks.length}', style: AppTextStyles.metadata.copyWith(fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSubtle, style: BorderStyle.solid),
              borderRadius: AppRadius.cardRadius,
            ),
            child: Text('Drop tasks here', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ),
        ...tasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TaskCard(task: task),
            )),
      ],
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final ProjectTask task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityColor = switch (task.priority) {
      TaskPriority.high => AppColors.statusDanger,
      TaskPriority.medium => AppColors.tertiary,
      TaskPriority.low => AppColors.statusSuccess,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: AppTextStyles.bodyMd.copyWith(
                    decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null,
                    color: task.status == TaskStatus.done ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
              ),
              // Schedule to Today Button
              if (task.status != TaskStatus.done && task.scheduledDate == null)
                GestureDetector(
                  onTap: () => ref.read(projectTaskProvider.notifier).scheduleForToday(task.id),
                  child: const Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.tertiary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: priorityColor),
              ),
              // Status cycle button
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
                    borderRadius: AppRadius.chipRadius,
                  ),
                  child: Text('Move ➔', style: AppTextStyles.metadata.copyWith(fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared action button
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
          borderRadius: AppRadius.chipRadius,
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/project_task.dart';
import 'package:life_flow/core/providers/database_provider.dart';
import 'package:uuid/uuid.dart';

// =============================================================================
// ProjectTaskNotifier — Manages Kanban tasks with filtering by project/status.
// Also provides getScheduledForToday() for the Today Nexus dashboard.
// =============================================================================

class ProjectTaskNotifier extends AsyncNotifier<List<ProjectTask>> {
  @override
  Future<List<ProjectTask>> build() async {
    final repo = ref.watch(projectTaskRepositoryProvider);
    return repo.getAll();
  }

  /// Add a new task to a project.
  Future<void> addTask({
    required String projectId,
    required String title,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    DateTime? scheduledDate,
  }) async {
    final repo = ref.read(projectTaskRepositoryProvider);
    final task = ProjectTask(
      id: const Uuid().v4(),
      projectId: projectId,
      title: title,
      priority: priority,
      dueDate: dueDate,
      scheduledDate: scheduledDate,
    );
    await repo.insert(task);
    state = AsyncData(await repo.getAll());
  }

  /// Update a task's status (e.g., Kanban drag from ToDo → InProgress).
  Future<void> updateStatus(String taskId, TaskStatus newStatus) async {
    final repo = ref.read(projectTaskRepositoryProvider);
    final tasks = state.valueOrNull ?? [];
    final task = tasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null) return;

    await repo.update(task.copyWith(status: newStatus));
    state = AsyncData(await repo.getAll());
  }

  /// Update a full task object.
  Future<void> updateTask(ProjectTask task) async {
    final repo = ref.read(projectTaskRepositoryProvider);
    await repo.update(task);
    state = AsyncData(await repo.getAll());
  }

  /// Schedule a task for today (sends it to "Today Nexus").
  Future<void> scheduleForToday(String taskId) async {
    final repo = ref.read(projectTaskRepositoryProvider);
    final tasks = state.valueOrNull ?? [];
    final task = tasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null) return;

    await repo.update(task.copyWith(scheduledDate: DateTime.now()));
    state = AsyncData(await repo.getAll());
  }

  /// Delete a task.
  Future<void> deleteTask(String id) async {
    final repo = ref.read(projectTaskRepositoryProvider);
    await repo.delete(id);
    state = AsyncData(await repo.getAll());
  }
}

/// Provider for all project tasks.
final projectTaskProvider =
    AsyncNotifierProvider<ProjectTaskNotifier, List<ProjectTask>>(() {
  return ProjectTaskNotifier();
});

// ─── Derived Providers ──────────────────────────────────────────────────────

/// Tasks scheduled for today (feeds into the Today Nexus dashboard).
final todayTasksProvider = FutureProvider<List<ProjectTask>>((ref) async {
  final repo = ref.watch(projectTaskRepositoryProvider);
  // Also re-compute when the main task list changes
  ref.watch(projectTaskProvider);
  return repo.getScheduledForDate(DateTime.now());
});

/// Tasks grouped by project ID (for the Kanban board view).
final tasksByProjectProvider =
    Provider<Map<String, List<ProjectTask>>>((ref) {
  final tasksAsync = ref.watch(projectTaskProvider);
  final tasks = tasksAsync.valueOrNull ?? [];

  final grouped = <String, List<ProjectTask>>{};
  for (final task in tasks) {
    grouped.putIfAbsent(task.projectId, () => []).add(task);
  }
  return grouped;
});

/// Tasks grouped by status (for Kanban column rendering).
final tasksByStatusProvider =
    Provider<Map<TaskStatus, List<ProjectTask>>>((ref) {
  final tasksAsync = ref.watch(projectTaskProvider);
  final tasks = tasksAsync.valueOrNull ?? [];

  return {
    for (final status in TaskStatus.values)
      status: tasks.where((t) => t.status == status).toList(),
  };
});

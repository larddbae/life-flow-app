import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/project.dart';
import 'package:life_flow/core/providers/database_provider.dart';
import 'package:uuid/uuid.dart';

// =============================================================================
// ProjectNotifier — Manages the list of Projects (task grouping containers).
// =============================================================================

class ProjectNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    final repo = ref.watch(projectRepositoryProvider);
    return repo.getAll();
  }

  /// Add a new project.
  Future<void> addProject({
    required String name,
    required String colorCode,
  }) async {
    final repo = ref.read(projectRepositoryProvider);
    final project = Project(
      id: const Uuid().v4(),
      name: name,
      colorCode: colorCode,
    );
    await repo.insert(project);
    state = AsyncData(await ref.read(projectRepositoryProvider).getAll());
  }

  /// Update a project's name or color.
  Future<void> updateProject(Project project) async {
    final repo = ref.read(projectRepositoryProvider);
    await repo.update(project);
    state = AsyncData(await repo.getAll());
  }

  /// Delete a project (cascades to all its tasks via FK).
  Future<void> deleteProject(String id) async {
    final repo = ref.read(projectRepositoryProvider);
    await repo.delete(id);
    state = AsyncData(await repo.getAll());
  }
}

/// Provider for the list of projects.
final projectProvider =
    AsyncNotifierProvider<ProjectNotifier, List<Project>>(() {
  return ProjectNotifier();
});

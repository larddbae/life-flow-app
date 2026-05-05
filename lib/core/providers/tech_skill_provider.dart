import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/tech_skill.dart';
import 'package:life_flow/core/providers/database_provider.dart';
import 'package:uuid/uuid.dart';

// =============================================================================
// TechSkillNotifier — Manages the "Learning Radar" skill board.
// =============================================================================

class TechSkillNotifier extends AsyncNotifier<List<TechSkill>> {
  @override
  Future<List<TechSkill>> build() async {
    final repo = ref.watch(techSkillRepositoryProvider);
    return repo.getAll();
  }

  /// Add a new tech skill to track.
  Future<void> addSkill({
    required String name,
    SkillStatus status = SkillStatus.planned,
    String? resourceUrl,
  }) async {
    final repo = ref.read(techSkillRepositoryProvider);
    final skill = TechSkill(
      id: const Uuid().v4(),
      name: name,
      status: status,
      resourceUrl: resourceUrl,
    );
    await repo.insert(skill);
    state = AsyncData(await repo.getAll());
  }

  /// Update a skill's status (planned → learning → mastered).
  Future<void> updateStatus(String id, SkillStatus newStatus) async {
    final repo = ref.read(techSkillRepositoryProvider);
    final skills = state.valueOrNull ?? [];
    final skill = skills.where((s) => s.id == id).firstOrNull;
    if (skill == null) return;

    await repo.update(skill.copyWith(status: newStatus));
    state = AsyncData(await repo.getAll());
  }

  /// Update a skill (name, url, etc.).
  Future<void> updateSkill(TechSkill skill) async {
    final repo = ref.read(techSkillRepositoryProvider);
    await repo.update(skill);
    state = AsyncData(await repo.getAll());
  }

  /// Delete a skill.
  Future<void> deleteSkill(String id) async {
    final repo = ref.read(techSkillRepositoryProvider);
    await repo.delete(id);
    state = AsyncData(await repo.getAll());
  }
}

/// Provider for the Learning Radar tech skills list.
final techSkillProvider =
    AsyncNotifierProvider<TechSkillNotifier, List<TechSkill>>(() {
  return TechSkillNotifier();
});

/// Skills filtered by status (for grouped display on the radar board).
final skillsByStatusProvider =
    Provider<Map<SkillStatus, List<TechSkill>>>((ref) {
  final skillsAsync = ref.watch(techSkillProvider);
  final skills = skillsAsync.valueOrNull ?? [];

  return {
    for (final status in SkillStatus.values)
      status: skills.where((s) => s.status == status).toList(),
  };
});

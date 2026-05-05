// =============================================================================
// TechSkill — Learning Radar
// Tracks tech stacks/skills the user is learning (e.g., React, Flutter, GSAP).
// =============================================================================

enum SkillStatus { planned, learning, mastered }

class TechSkill {
  final String id; // UUID
  final String name;
  final SkillStatus status;
  final String? resourceUrl;

  const TechSkill({
    required this.id,
    required this.name,
    this.status = SkillStatus.planned,
    this.resourceUrl,
  });

  TechSkill copyWith({
    String? id,
    String? name,
    SkillStatus? status,
    String? resourceUrl,
  }) {
    return TechSkill(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      resourceUrl: resourceUrl ?? this.resourceUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status.name,
      'resource_url': resourceUrl,
    };
  }

  factory TechSkill.fromMap(Map<String, dynamic> map) {
    return TechSkill(
      id: map['id'] as String,
      name: map['name'] as String,
      status: SkillStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SkillStatus.planned,
      ),
      resourceUrl: map['resource_url'] as String?,
    );
  }

  @override
  String toString() =>
      'TechSkill(id: $id, name: $name, status: ${status.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TechSkill &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// =============================================================================
// Project — Groups tasks together
// Represents a school subject or personal project (e.g., "RPL App", "School").
// =============================================================================

class Project {
  final String id; // UUID
  final String name;
  final String colorCode; // Hex color, e.g., "#5C6BC0"

  const Project({
    required this.id,
    required this.name,
    required this.colorCode,
  });

  Project copyWith({
    String? id,
    String? name,
    String? colorCode,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      colorCode: colorCode ?? this.colorCode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_code': colorCode,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      colorCode: map['color_code'] as String,
    );
  }

  @override
  String toString() => 'Project(id: $id, name: $name, color: $colorCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

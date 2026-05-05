// =============================================================================
// ProjectTask — Kanban Tasks
// Tasks belong to a Project. scheduledDate feeds into "Today Nexus" when set.
// =============================================================================

enum TaskStatus { toDo, inProgress, blocked, done }

enum TaskPriority { low, medium, high }

class ProjectTask {
  final String id; // UUID
  final String projectId; // FK → Project(id)
  final String title;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime? scheduledDate; // Feeds into "Today Nexus"
  final TaskPriority priority;

  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.status = TaskStatus.toDo,
    this.dueDate,
    this.scheduledDate,
    this.priority = TaskPriority.medium,
  });

  ProjectTask copyWith({
    String? id,
    String? projectId,
    String? title,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? scheduledDate,
    TaskPriority? priority,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'status': status.name,
      'due_date': dueDate?.toIso8601String(),
      'scheduled_date': scheduledDate?.toIso8601String(),
      'priority': priority.name,
    };
  }

  factory ProjectTask.fromMap(Map<String, dynamic> map) {
    return ProjectTask(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      title: map['title'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.toDo,
      ),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      scheduledDate: map['scheduled_date'] != null
          ? DateTime.parse(map['scheduled_date'] as String)
          : null,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
    );
  }

  @override
  String toString() =>
      'ProjectTask(id: $id, title: $title, status: ${status.name}, priority: ${priority.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectTask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

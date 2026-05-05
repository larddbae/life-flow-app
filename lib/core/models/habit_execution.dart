// =============================================================================
// HabitExecution — Daily habit logs
// Records whether a habit was completed on a given day, plus optional value.
// =============================================================================

class HabitExecution {
  final String id; // UUID
  final String habitId; // FK → Habit(id)
  final DateTime executionDate;
  final bool isCompleted;
  final int? recordedValue; // e.g., pages read, reps done

  const HabitExecution({
    required this.id,
    required this.habitId,
    required this.executionDate,
    this.isCompleted = false,
    this.recordedValue,
  });

  HabitExecution copyWith({
    String? id,
    String? habitId,
    DateTime? executionDate,
    bool? isCompleted,
    int? recordedValue,
  }) {
    return HabitExecution(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      executionDate: executionDate ?? this.executionDate,
      isCompleted: isCompleted ?? this.isCompleted,
      recordedValue: recordedValue ?? this.recordedValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'execution_date': executionDate.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0, // SQLite boolean
      'recorded_value': recordedValue,
    };
  }

  factory HabitExecution.fromMap(Map<String, dynamic> map) {
    return HabitExecution(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      executionDate: DateTime.parse(map['execution_date'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
      recordedValue: map['recorded_value'] as int?,
    );
  }

  @override
  String toString() =>
      'HabitExecution(id: $id, habitId: $habitId, date: $executionDate, done: $isCompleted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitExecution &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// =============================================================================
// Habit — Routine Templates
// Defines recurring habits. activeDays stored as comma-separated ints in DB.
// moduleType determines the tracking input: Boolean, Timer, or Counter.
// =============================================================================

enum FrequencyType { daily, specificDays }

enum ModuleType { boolean, timer, counter }

class Habit {
  final String id; // UUID
  final String title;
  final FrequencyType frequencyType;
  final List<int> activeDays; // 1=Mon .. 7=Sun (ISO weekday)
  final ModuleType moduleType;
  final int? targetValue; // e.g., 25 mins, 3 chapters

  const Habit({
    required this.id,
    required this.title,
    this.frequencyType = FrequencyType.daily,
    this.activeDays = const [],
    this.moduleType = ModuleType.boolean,
    this.targetValue,
  });

  Habit copyWith({
    String? id,
    String? title,
    FrequencyType? frequencyType,
    List<int>? activeDays,
    ModuleType? moduleType,
    int? targetValue,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      frequencyType: frequencyType ?? this.frequencyType,
      activeDays: activeDays ?? this.activeDays,
      moduleType: moduleType ?? this.moduleType,
      targetValue: targetValue ?? this.targetValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'frequency_type': frequencyType.name,
      'active_days': activeDays.join(','), // "1,3,5"
      'module_type': moduleType.name,
      'target_value': targetValue,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    final daysStr = map['active_days'] as String? ?? '';
    final days = daysStr.isEmpty
        ? <int>[]
        : daysStr.split(',').map((e) => int.parse(e.trim())).toList();

    return Habit(
      id: map['id'] as String,
      title: map['title'] as String,
      frequencyType: FrequencyType.values.firstWhere(
        (e) => e.name == map['frequency_type'],
        orElse: () => FrequencyType.daily,
      ),
      activeDays: days,
      moduleType: ModuleType.values.firstWhere(
        (e) => e.name == map['module_type'],
        orElse: () => ModuleType.boolean,
      ),
      targetValue: map['target_value'] as int?,
    );
  }

  /// Returns true if this habit should be active on the given weekday.
  bool isActiveOn(int weekday) {
    if (frequencyType == FrequencyType.daily) return true;
    return activeDays.contains(weekday);
  }

  @override
  String toString() =>
      'Habit(id: $id, title: $title, type: ${moduleType.name}, freq: ${frequencyType.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Habit && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

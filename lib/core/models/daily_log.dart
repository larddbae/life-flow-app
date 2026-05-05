// =============================================================================
// DailyLog — Tracks daily energy and manual journal
// PK is date-string YYYY-MM-DD (one entry per day).
// =============================================================================

class DailyLog {
  final String id; // YYYY-MM-DD
  final int energyLevel; // 1–5
  final String? journalNotes;
  final DateTime createdAt;

  const DailyLog({
    required this.id,
    required this.energyLevel,
    this.journalNotes,
    required this.createdAt,
  });

  DailyLog copyWith({
    String? id,
    int? energyLevel,
    String? journalNotes,
    DateTime? createdAt,
  }) {
    return DailyLog(
      id: id ?? this.id,
      energyLevel: energyLevel ?? this.energyLevel,
      journalNotes: journalNotes ?? this.journalNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'energy_level': energyLevel,
      'journal_notes': journalNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'] as String,
      energyLevel: map['energy_level'] as int,
      journalNotes: map['journal_notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() =>
      'DailyLog(id: $id, energy: $energyLevel, notes: $journalNotes)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLog && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

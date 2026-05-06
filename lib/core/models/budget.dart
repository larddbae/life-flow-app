// =============================================================================
// Budget — User-defined spending limits
// =============================================================================

class Budget {
  final String category;
  final double targetLimit;

  const Budget({
    required this.category,
    required this.targetLimit,
  });

  Budget copyWith({
    String? category,
    double? targetLimit,
  }) {
    return Budget(
      category: category ?? this.category,
      targetLimit: targetLimit ?? this.targetLimit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'target_limit': targetLimit,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      category: map['category'] as String,
      targetLimit: (map['target_limit'] as num).toDouble(),
    );
  }

  @override
  String toString() => 'Budget(category: $category, targetLimit: $targetLimit)';
}

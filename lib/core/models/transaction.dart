// =============================================================================
// Transaction — Financial Tracking
// Logs income/expense entries. When wishlistId is non-null, the transaction
// represents funds allocated towards a savings goal (Wishlist item).
// =============================================================================

enum TransactionType { income, expense }

class Transaction {
  final String id; // UUID
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? wishlistId; // FK → Wishlist(id), nullable
  final String? notes; // Optional notes/description

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.wishlistId,
    this.notes,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? wishlistId,
    String? notes,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      wishlistId: wishlistId ?? this.wishlistId,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
      'wishlist_id': wishlistId,
      'notes': notes,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      wishlistId: map['wishlist_id'] as String?,
      notes: map['notes'] as String?,
    );
  }

  @override
  String toString() =>
      'Transaction(id: $id, amount: $amount, type: ${type.name}, category: $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

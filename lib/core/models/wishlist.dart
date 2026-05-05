// =============================================================================
// Wishlist — Savings Goals
// Tracks items the user wants to save towards (e.g., gadgets, courses).
// Funded amount is computed by summing Transactions with this wishlistId.
// =============================================================================

enum WishlistStatus { active, achieved }

class Wishlist {
  final String id; // UUID
  final String itemName;
  final double targetAmount;
  final WishlistStatus status;
  final String? url;
  final DateTime createdAt;

  const Wishlist({
    required this.id,
    required this.itemName,
    required this.targetAmount,
    this.status = WishlistStatus.active,
    this.url,
    required this.createdAt,
  });

  Wishlist copyWith({
    String? id,
    String? itemName,
    double? targetAmount,
    WishlistStatus? status,
    String? url,
    DateTime? createdAt,
  }) {
    return Wishlist(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      targetAmount: targetAmount ?? this.targetAmount,
      status: status ?? this.status,
      url: url ?? this.url,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_name': itemName,
      'target_amount': targetAmount,
      'status': status.name,
      'url': url,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Wishlist.fromMap(Map<String, dynamic> map) {
    return Wishlist(
      id: map['id'] as String,
      itemName: map['item_name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      status: WishlistStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WishlistStatus.active,
      ),
      url: map['url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() =>
      'Wishlist(id: $id, name: $itemName, target: $targetAmount, status: ${status.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wishlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/models/wishlist.dart';
import 'package:life_flow/core/providers/database_provider.dart';
import 'package:uuid/uuid.dart';

// =============================================================================
// WishlistWithFunding — Composite model pairing a Wishlist with its funded $.
// =============================================================================

class WishlistWithFunding {
  final Wishlist wishlist;
  final double fundedAmount;

  const WishlistWithFunding({
    required this.wishlist,
    required this.fundedAmount,
  });

  /// Progress ratio (0.0–1.0) toward the savings goal.
  double get progress =>
      wishlist.targetAmount > 0 ? fundedAmount / wishlist.targetAmount : 0;

  /// Whether the goal is fully funded.
  bool get isFullyFunded => fundedAmount >= wishlist.targetAmount;
}

// =============================================================================
// WishlistNotifier — Manages savings goals with live funding data.
// =============================================================================

class WishlistNotifier extends AsyncNotifier<List<WishlistWithFunding>> {
  @override
  Future<List<WishlistWithFunding>> build() async {
    return _loadAll();
  }

  Future<List<WishlistWithFunding>> _loadAll() async {
    final wishlistRepo = ref.read(wishlistRepositoryProvider);
    final txnRepo = ref.read(transactionRepositoryProvider);
    final wishlists = await wishlistRepo.getAll();

    final results = <WishlistWithFunding>[];
    for (final w in wishlists) {
      final funded = await txnRepo.getTotalFundedForWishlist(w.id);
      results.add(WishlistWithFunding(wishlist: w, fundedAmount: funded));
    }
    return results;
  }

  /// Add a new wishlist savings goal.
  Future<void> addWishlist({
    required String itemName,
    required double targetAmount,
    String? url,
  }) async {
    final repo = ref.read(wishlistRepositoryProvider);
    final item = Wishlist(
      id: const Uuid().v4(),
      itemName: itemName,
      targetAmount: targetAmount,
      url: url,
      createdAt: DateTime.now(),
    );
    await repo.insert(item);
    state = AsyncData(await _loadAll());
  }

  /// Mark a wishlist item as achieved.
  Future<void> markAchieved(String id) async {
    final repo = ref.read(wishlistRepositoryProvider);
    final item = await repo.getById(id);
    if (item == null) return;
    await repo.update(item.copyWith(status: WishlistStatus.achieved));
    state = AsyncData(await _loadAll());
  }

  /// Delete a wishlist item.
  Future<void> deleteWishlist(String id) async {
    final repo = ref.read(wishlistRepositoryProvider);
    await repo.delete(id);
    state = AsyncData(await _loadAll());
  }

  /// Refresh funding totals (call after a transaction is added/deleted).
  Future<void> refresh() async {
    state = AsyncData(await _loadAll());
  }
}

/// Provider for wishlist savings goals with funding data.
final wishlistProvider =
    AsyncNotifierProvider<WishlistNotifier, List<WishlistWithFunding>>(() {
  return WishlistNotifier();
});

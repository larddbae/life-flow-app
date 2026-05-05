import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// Navigation State — Controls which page is active in the bottom nav bar.
// Index mapping: 0=Dashboard, 1=Finance, 2=Board, 3=Routines, 4=Reflect
// =============================================================================

/// Global provider for the bottom navigation bar's active index.
///
/// Usage:
/// ```dart
/// // Read current index
/// final index = ref.watch(navBarIndexProvider);
///
/// // Change page
/// ref.read(navBarIndexProvider.notifier).state = 2;
/// ```
final navBarIndexProvider = StateProvider<int>((ref) => 0);

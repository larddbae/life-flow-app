import 'package:flutter/material.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// SectionLabel — Uppercase muted section header
// Reusable across all screens for section titles like "TODAY'S SCHEDULE".
// =============================================================================

/// A standardized section label using the `label-caps` typography.
///
/// Renders uppercase, letter-spaced, muted text matching the design system.
///
/// ```dart
/// SectionLabel(text: "Today's Schedule")
/// ```
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelCaps,
    );
  }
}

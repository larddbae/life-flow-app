import 'package:flutter/material.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// FinancialGlanceCard — Daily budget summary with progress bar
// Shows wallet icon, budget label, amount, and linear progress indicator.
// =============================================================================

/// A summary card showing the user's remaining daily budget.
///
/// Mirrors the Stitch design: wallet icon in a circular surface-variant
/// container, metadata label, headline-lg amount, and a thin indigo
/// linear progress bar.
///
/// ```dart
/// FinancialGlanceCard(
///   label: 'Daily Budget Remaining',
///   amount: 'Rp 85,000',
///   progress: 0.6,
/// )
/// ```
class FinancialGlanceCard extends StatelessWidget {
  /// Label text displayed above the amount (e.g., "Daily Budget Remaining").
  final String label;

  /// Formatted amount string (e.g., "Rp 85,000").
  final String amount;

  /// Progress value from 0.0 to 1.0 representing budget usage.
  final double progress;

  const FinancialGlanceCard({
    super.key,
    required this.label,
    required this.amount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon + Text Row ─────────────────────────────────────────
          Row(
            children: [
              // Wallet icon in circular container
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Budget label + amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.metadata),
                    const SizedBox(height: 2),
                    Text(amount, style: AppTextStyles.headlineLg),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Progress bar ──────────────────────────────────────────
          ClipRRect(
            borderRadius: AppRadius.chipRadius,
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceVariant,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.accentIndigo),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

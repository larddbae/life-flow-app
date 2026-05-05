import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/providers/daily_log_provider.dart';
import 'package:life_flow/core/providers/transaction_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';
import 'package:life_flow/shared/widgets/section_label.dart';

// =============================================================================
// ReflectionScreen — Monthly Insights & Daily Journaling (LIVE)
// =============================================================================

class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key});

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  final _journalController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  void _saveJournal(WidgetRef ref) {
    ref.read(dailyLogProvider.notifier).updateJournal(_journalController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Journal saved', style: AppTextStyles.metadata),
        backgroundColor: AppColors.surfaceCard,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch daily log to populate initial journal text
    final dailyLogAsync = ref.watch(dailyLogProvider);
    
    if (!_isInitialized && dailyLogAsync.hasValue) {
      final text = dailyLogAsync.value?.journalNotes ?? '';
      _journalController.text = text;
      _isInitialized = true;
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reflection', style: AppTextStyles.headlineXl),
                  const SizedBox(height: 8),
                  Text('Insights & journaling',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),

                  // ── Automated Insights Section ─────────────────────────
                  const SectionLabel(text: 'Monthly Insights'),
                  const SizedBox(height: 12),
                  const _FinancialInsightCard(),
                  const SizedBox(height: 12),
                  const _EnergyInsightCard(),
                  const SizedBox(height: 24),

                  // ── Daily Journal Section ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionLabel(text: "Today's Journal"),
                      GestureDetector(
                        onTap: () => _saveJournal(ref),
                        child: Text(
                          'SAVE',
                          style: AppTextStyles.metadata.copyWith(
                            color: AppColors.accentIndigo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: TextField(
                      controller: _journalController,
                      maxLines: null,
                      style: AppTextStyles.bodyMd,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'What\'s on your mind today?',
                        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom clearance for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// =============================================================================
// Insight Cards
// =============================================================================

class _FinancialInsightCard extends ConsumerWidget {
  const _FinancialInsightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(transactionProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentIndigo.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.insights, color: AppColors.accentIndigo, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financial Health', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                txnAsync.when(
                  loading: () => Text('Analyzing...', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                  error: (e, _) => Text('Error loading data', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                  data: (state) {
                    final savingsRate = state.monthlyIncome > 0 
                      ? ((state.monthlyIncome - state.monthlyExpenses) / state.monthlyIncome * 100).clamp(0, 100).round()
                      : 0;
                    
                    return Text(
                      'Your savings rate this month is $savingsRate%. ${savingsRate > 20 ? "Great job!" : "Keep an eye on expenses."}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary, height: 1.4),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyInsightCard extends ConsumerWidget {
  const _EnergyInsightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(dailyLogProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.battery_charging_full, color: AppColors.tertiary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Energy Trend', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                logAsync.when(
                  loading: () => Text('Analyzing...', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                  error: (e, _) => Text('Error loading data', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                  data: (log) {
                    final level = log?.energyLevel;
                    String message = "Not enough data yet.";
                    if (level != null) {
                      if (level >= 4) {
                        message = "You're running on high energy today! Good time to tackle difficult tasks.";
                      } else if (level == 3) {
                        message = "Your energy is steady. Keep a balanced pace.";
                      } else {
                        message = "Your energy is low today. Remember to rest and prioritize recovery.";
                      }
                    }
                    
                    return Text(
                      message,
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary, height: 1.4),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

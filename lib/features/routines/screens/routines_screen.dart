import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/providers/habit_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';
import 'package:life_flow/features/routines/widgets/add_habit_sheet.dart';
import 'package:life_flow/features/today_nexus/widgets/habit_quick_check.dart';
import 'package:life_flow/shared/widgets/section_label.dart';

// =============================================================================
// RoutinesScreen — Habits and weekly templates (LIVE)
// =============================================================================

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Routines', style: AppTextStyles.headlineXl),
                      ),
                      _ActionButton(
                        icon: Icons.add,
                        label: 'Habit',
                        onTap: () => _showSheet(context, const AddHabitSheet()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Today's Active Habits ──────────────────────────
                  const SectionLabel(text: "Today's Active Habits"),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Today's Habits List ────────────────────────────────────
          const _TodayHabitsSliver(),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: const SectionLabel(text: 'All Habit Templates'),
            ),
          ),

          // ── All Templates List ─────────────────────────────────────
          const _AllHabitsSliver(),

          // Bottom clearance for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => sheet,
    );
  }
}

// =============================================================================
// Today's Habits Sliver — Tap-to-complete tiles for active day
// =============================================================================

class _TodayHabitsSliver extends ConsumerWidget {
  const _TodayHabitsSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitProvider);

    return habitsAsync.when(
      loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (habits) {
        if (habits.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text('No habits scheduled for today. Rest up!',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final h = habits[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: HabitQuickCheckTile(
                  title: h.habit.title,
                  isCompleted: h.isCompletedToday,
                  moduleType: h.habit.moduleType.name,
                  targetValue: h.habit.targetValue,
                  recordedValue: h.todayValue,
                  onToggle: () {
                    ref.read(habitProvider.notifier).toggleCompletion(h.habit.id);
                  },
                ),
              );
            },
            childCount: habits.length,
          ),
        );
      },
    );
  }
}

// =============================================================================
// All Habits Sliver — Master list of templates with stats/edit options
// =============================================================================

class _AllHabitsSliver extends ConsumerWidget {
  const _AllHabitsSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allHabitsAsync = ref.watch(allHabitsProvider);

    return allHabitsAsync.when(
      loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (habits) {
        if (habits.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text('You haven\'t created any habit templates yet.',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final habit = habits[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(habit.title,
                                style: AppTextStyles.bodyMd.copyWith(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              habit.frequencyType.name == 'daily'
                                  ? 'Daily'
                                  : 'Days: ${habit.activeDays.map((d) => ['M','T','W','T','F','S','S'][d-1]).join(', ')}',
                              style: AppTextStyles.metadata,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.statusDanger, size: 20),
                        onPressed: () {
                          ref.read(habitProvider.notifier).deleteHabit(habit.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: habits.length,
          ),
        );
      },
    );
  }
}

// =============================================================================
// Shared small action button
// =============================================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentIndigo.withValues(alpha: 0.12),
          borderRadius: AppRadius.chipRadius,
          border: Border.all(
              color: AppColors.accentIndigo.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.accentIndigo),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.metadata.copyWith(
                    color: AppColors.accentIndigo,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

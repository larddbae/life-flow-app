import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/providers/daily_log_provider.dart';
import 'package:life_flow/core/providers/reflection_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';
import 'package:life_flow/features/reflection/widgets/reflection_history_sheet.dart';

// =============================================================================
// ReflectionScreen — Monthly Insights & Daily Journaling (FULLY WIRED)
// =============================================================================

class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key});

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  final _wellController = TextEditingController();
  final _improveController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _wellController.dispose();
    _improveController.dispose();
    super.dispose();
  }

  void _saveJournal(WidgetRef ref) {
    final combined = '${_wellController.text} ||| ${_improveController.text}';
    ref.read(dailyLogProvider.notifier).updateJournal(combined);
    
    // Invalidate history so it refetches
    ref.invalidate(reflectionHistoryProvider);

    // Unfocus the keyboard
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reflection saved', style: AppTextStyles.bodySm),
        backgroundColor: AppColors.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dailyLogAsync = ref.watch(dailyLogProvider);

    if (!_isInitialized && dailyLogAsync.hasValue) {
      final text = dailyLogAsync.value?.journalNotes ?? '';
      final parts = text.split(' ||| ');
      _wellController.text = parts.isNotEmpty ? parts[0] : '';
      _improveController.text = parts.length > 1 ? parts[1] : '';
      _isInitialized = true;
    }

    // Month selector state
    final selectedMonth = ref.watch(reflectionMonthProvider);
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthName = '${months[selectedMonth.month - 1]} ${selectedMonth.year}';

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header & Month Selector ─────────────────────────────────
                  Text('Reflection', style: AppTextStyles.headlineXl, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final current = ref.read(reflectionMonthProvider);
                          ref.read(reflectionMonthProvider.notifier).state =
                              DateTime(current.year, current.month - 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.chevron_left, size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(monthName, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          final current = ref.read(reflectionMonthProvider);
                          ref.read(reflectionMonthProvider.notifier).state =
                              DateTime(current.year, current.month + 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── This Month at a Glance ─────────────────────────────────
                  Text('THIS MONTH AT A GLANCE', style: AppTextStyles.labelCaps.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  const _InsightsSummaryGrid(),
                  const SizedBox(height: 32),

                  // ── Productivity vs. Energy Chart ──────────────────────────
                  const _ChartSection(),
                  const SizedBox(height: 32),

                  // ── Habit Consistency Heatmap ──────────────────────────────
                  const _HabitHeatmapSection(),
                  const SizedBox(height: 32),

                  // ── Qualitative Reflection ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('✍️', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Qualitative Reflection', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
                            ),
                            // View History button
                            GestureDetector(
                              onTap: () => ReflectionHistorySheet.show(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.accentIndigo.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.history, size: 14, color: AppColors.accentIndigo),
                                    const SizedBox(width: 4),
                                    Text(
                                      'History',
                                      style: AppTextStyles.metadata.copyWith(
                                        color: AppColors.accentIndigo,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('What went well?', style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        _buildTextField(_wellController, 'Reflect on your wins...'),
                        const SizedBox(height: 16),
                        Text('What to improve?', style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        _buildTextField(_improveController, 'Where did you struggle?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Save Button ──────────────────────────────────────────
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _saveJournal(ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentIndigo,
                        foregroundColor: AppColors.onPrimaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Text('Save Reflection', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppTextStyles.bodySm.copyWith(color: const Color(0xFF555555)),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}

// =============================================================================
// Insights Summary Grid — Real data from reflectionMetricsProvider
// =============================================================================

class _InsightsSummaryGrid extends ConsumerWidget {
  const _InsightsSummaryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(reflectionMetricsProvider);

    return metricsAsync.when(
      loading: () => Row(
        children: [
          Expanded(child: _InsightCard(value: '—', label: 'of habits completed', valueColor: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(child: _InsightCard(value: '—', label: 'of income saved', valueColor: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(child: _InsightCard(value: '—', label: 'longest habit streak', valueColor: AppColors.textSecondary)),
        ],
      ),
      error: (error, stackTrace) => Row(
        children: [
          Expanded(child: _InsightCard(value: '!', label: 'error', valueColor: AppColors.error)),
          const SizedBox(width: 12),
          Expanded(child: _InsightCard(value: '!', label: 'error', valueColor: AppColors.error)),
          const SizedBox(width: 12),
          Expanded(child: _InsightCard(value: '!', label: 'error', valueColor: AppColors.error)),
        ],
      ),
      data: (metrics) => Row(
        children: [
          Expanded(
            child: _InsightCard(
              value: '${metrics.habitCompletionPct}%',
              label: 'of habits completed',
              valueColor: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InsightCard(
              value: '${metrics.incomeSavedPct}%',
              label: 'of income saved',
              valueColor: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InsightCard(
              value: '${metrics.longestStreakDays}d',
              label: 'longest habit streak',
              valueColor: AppColors.accentIndigo,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _InsightCard({required this.value, required this.label, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.headlineLg.copyWith(color: valueColor)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary, height: 1.2), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// =============================================================================
// Chart Section — Real Productivity vs. Energy from reflectionChartDataProvider
// =============================================================================

class _ChartSection extends ConsumerWidget {
  const _ChartSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(reflectionChartDataProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: AppColors.accentIndigo, size: 20),
              const SizedBox(width: 8),
              Text('Productivity vs. Energy', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 24),

          // The Chart Area
          Container(
            height: 192,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle),
                left: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: chartAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentIndigo,
                  strokeWidth: 2,
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Text('No data', style: AppTextStyles.metadata),
              ),
              data: (data) => Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ChartPainter(data: data),
                    ),
                  ),
                  Positioned(
                    bottom: -24,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1', style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                        Text('${(data.length * 0.33).round()}', style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                        Text('${(data.length * 0.66).round()}', style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                        Text('${data.length}', style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(width: 12, height: 2, color: AppColors.accentIndigo),
                  const SizedBox(width: 8),
                  Text('Tasks Completed', style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  SizedBox(
                    width: 12, height: 2,
                    child: Row(
                      children: [
                        Expanded(child: Container(color: AppColors.statusWarning)),
                        const SizedBox(width: 2),
                        Expanded(child: Container(color: AppColors.statusWarning)),
                        const SizedBox(width: 2),
                        Expanded(child: Container(color: AppColors.statusWarning)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Energy Level', style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws real productivity & energy lines from [data].
class _ChartPainter extends CustomPainter {
  final List<ChartDayData> data;

  _ChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final days = data.length;

    // Find max values for normalization
    final maxTasks = data.map((d) => d.tasksCompleted).reduce(math.max).clamp(1, 999);
    const maxEnergy = 5; // Fixed scale 1–5

    // ── Energy Line (Dashed Amber) ────────────────────────────────────────
    final energyPoints = <Offset>[];
    for (int i = 0; i < days; i++) {
      if (data[i].energyLevel > 0) {
        final x = (i / (days - 1)) * size.width;
        final y = size.height - (data[i].energyLevel / maxEnergy) * size.height;
        energyPoints.add(Offset(x, y));
      }
    }

    if (energyPoints.length >= 2) {
      final energyPath = _smoothPath(energyPoints);
      final energyPaint = Paint()
        ..color = AppColors.statusWarning
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final dashPath = _createDashedPath(energyPath, 4, 4);
      canvas.drawPath(dashPath, energyPaint);

      // Draw energy dots
      final dotPaint = Paint()
        ..color = AppColors.statusWarning
        ..style = PaintingStyle.fill;
      for (final pt in energyPoints) {
        canvas.drawCircle(pt, 2.5, dotPaint);
      }
    }

    // ── Productivity Line (Solid Indigo) ──────────────────────────────────
    final prodPoints = <Offset>[];
    for (int i = 0; i < days; i++) {
      final x = (i / (days - 1)) * size.width;
      final y = size.height - (data[i].tasksCompleted / maxTasks) * size.height;
      prodPoints.add(Offset(x, y));
    }

    if (prodPoints.length >= 2) {
      final prodPath = _smoothPath(prodPoints);
      final prodPaint = Paint()
        ..color = AppColors.accentIndigo
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(prodPath, prodPaint);

      // Fill under the curve with a subtle gradient
      final fillPath = Path.from(prodPath)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accentIndigo.withValues(alpha: 0.15),
            AppColors.accentIndigo.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);

      // Draw productivity dots
      final dotPaint = Paint()
        ..color = AppColors.accentIndigo
        ..style = PaintingStyle.fill;
      for (final pt in prodPoints) {
        canvas.drawCircle(pt, 2.5, dotPaint);
      }
    }
  }

  /// Creates a smooth bezier path through the given points.
  Path _smoothPath(List<Offset> points) {
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    return path;
  }

  Path _createDashedPath(Path source, double dashLength, double dashSpace) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : dashSpace;
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + length), Offset.zero);
        }
        distance += length;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.data != data;
}

// =============================================================================
// Habit Heatmap Section — Real data from reflectionHeatmapProvider
// =============================================================================

class _HabitHeatmapSection extends ConsumerWidget {
  const _HabitHeatmapSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(reflectionHeatmapProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view, color: AppColors.accentIndigo, size: 20),
              const SizedBox(width: 8),
              Text('Habit Consistency Heatmap', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),

          heatmapAsync.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentIndigo, strokeWidth: 2),
              ),
            ),
            error: (error, stackTrace) => SizedBox(
              height: 160,
              child: Center(child: Text('Error', style: AppTextStyles.metadata)),
            ),
            data: (heatmapData) {
              if (heatmapData.isEmpty) {
                return SizedBox(
                  height: 160,
                  child: Center(child: Text('No data', style: AppTextStyles.metadata)),
                );
              }

              // Determine the starting weekday offset for the first day
              final firstDay = heatmapData.first.date;
              // Monday = 1 (ISO), we want Mon at index 0
              final startOffset = (firstDay.weekday - 1) % 7;
              final totalCells = startOffset + heatmapData.length;
              // Pad to fill complete rows of 7
              final paddedTotal = ((totalCells + 6) ~/ 7) * 7;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: paddedTotal + 7, // +7 for day headers
                itemBuilder: (context, index) {
                  // Day name headers
                  if (index < 7) {
                    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return Center(
                      child: Text(dayLetters[index],
                          style: AppTextStyles.metadata
                              .copyWith(color: AppColors.textSecondary)),
                    );
                  }

                  final cellIndex = index - 7;

                  // Before the month starts — empty cell
                  if (cellIndex < startOffset) {
                    return const SizedBox.shrink();
                  }

                  // After the month ends — empty cell
                  final dayIndex = cellIndex - startOffset;
                  if (dayIndex >= heatmapData.length) {
                    return const SizedBox.shrink();
                  }

                  final dayData = heatmapData[dayIndex];
                  final pct = dayData.completionPct;

                  Color cellColor;
                  if (pct <= 0) {
                    cellColor = const Color(0xFF3A3A3A);
                  } else if (pct < 0.33) {
                    cellColor = AppColors.accentIndigo.withValues(alpha: 0.25);
                  } else if (pct < 0.66) {
                    cellColor = AppColors.accentIndigo.withValues(alpha: 0.5);
                  } else if (pct < 1.0) {
                    cellColor = AppColors.accentIndigo.withValues(alpha: 0.75);
                  } else {
                    cellColor = AppColors.accentIndigo;
                  }

                  return Tooltip(
                    message: '${dayData.date.day}: ${(pct * 100).round()}%',
                    child: Container(
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${dayData.date.day}',
                          style: AppTextStyles.metadata.copyWith(
                            fontSize: 10,
                            color: pct > 0.5
                                ? AppColors.textPrimary
                                : AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Color legend
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Less ', style: AppTextStyles.metadata.copyWith(fontSize: 10, color: AppColors.textSecondary)),
              ...[0.0, 0.25, 0.5, 0.75, 1.0].map((pct) => Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: pct <= 0
                      ? const Color(0xFF3A3A3A)
                      : AppColors.accentIndigo.withValues(alpha: pct.clamp(0.25, 1.0)),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
              Text(' More', style: AppTextStyles.metadata.copyWith(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_flow/core/providers/daily_log_provider.dart';
import 'package:life_flow/core/providers/transaction_provider.dart';
import 'package:life_flow/core/theme/app_theme.dart';

// =============================================================================
// ReflectionScreen — Monthly Insights & Daily Journaling (RESTORED UI)
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

    final now = DateTime.now();
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthName = '${months[now.month - 1]} ${now.year}';

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
                      const Icon(Icons.chevron_left, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 16),
                      Text(monthName, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 16),
                      const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
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
                            Text('Qualitative Reflection', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
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
// Insights Summary Grid
// =============================================================================

class _InsightsSummaryGrid extends ConsumerWidget {
  const _InsightsSummaryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(transactionProvider);
    final savingsRate = txnAsync.maybeWhen(
      data: (state) => state.monthlyIncome > 0 
          ? ((state.monthlyIncome - state.monthlyExpenses) / state.monthlyIncome * 100).clamp(0, 100).round()
          : 0,
      orElse: () => 0,
    );

    return Row(
      children: [
        Expanded(child: _InsightCard(value: '78%', label: 'of habits completed', valueColor: AppColors.textPrimary)),
        const SizedBox(width: 12),
        Expanded(child: _InsightCard(value: '$savingsRate%', label: 'of income saved', valueColor: AppColors.textPrimary)),
        const SizedBox(width: 12),
        Expanded(child: _InsightCard(value: '12 days', label: 'longest habit streak', valueColor: AppColors.accentIndigo)),
      ],
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
// Chart Section
// =============================================================================

class _ChartSection extends StatelessWidget {
  const _ChartSection();

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
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ChartPainter(),
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
                      Text('10', style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                      Text('20', style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                      Text('30', style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
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

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Energy Line (Dashed Amber)
    final energyPath = Path();
    energyPath.moveTo(0, size.height * 0.6);
    energyPath.quadraticBezierTo(size.width * 0.1, size.height * 0.4, size.width * 0.2, size.height * 0.5);
    energyPath.quadraticBezierTo(size.width * 0.4, size.height * 0.3, size.width * 0.6, size.height * 0.7);
    energyPath.quadraticBezierTo(size.width * 0.8, size.height * 0.2, size.width, size.height * 0.4);

    final energyPaint = Paint()
      ..color = AppColors.statusWarning
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
      
    final dashPath = _createDashedPath(energyPath, 4, 4);
    canvas.drawPath(dashPath, energyPaint);

    // Productivity Line (Solid Indigo)
    final prodPath = Path();
    prodPath.moveTo(0, size.height * 0.8);
    prodPath.quadraticBezierTo(size.width * 0.15, size.height * 0.7, size.width * 0.25, size.height * 0.3);
    prodPath.quadraticBezierTo(size.width * 0.45, size.height * 0.5, size.width * 0.65, size.height * 0.2);
    prodPath.quadraticBezierTo(size.width * 0.85, size.height * 0.6, size.width, size.height * 0.1);

    final prodPaint = Paint()
      ..color = AppColors.accentIndigo
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(prodPath, prodPaint);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// Habit Heatmap Section
// =============================================================================

class _HabitHeatmapSection extends StatelessWidget {
  const _HabitHeatmapSection();

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
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 35 + 7, // 7 days header + 35 cells
            itemBuilder: (context, index) {
              if (index < 7) {
                final dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Center(
                  child: Text(dayLetters[index], style: AppTextStyles.metadata.copyWith(color: AppColors.textSecondary)),
                );
              }
              
              final cellIndex = index - 7;
              Color cellColor = AppColors.surfaceVariant;
              
              if (cellIndex >= 31) {
                cellColor = Colors.transparent;
              } else {
                int mod = cellIndex % 5;
                if (mod == 0) {
                  cellColor = const Color(0xFF3A3A3A);
                } else if (mod == 1) {
                  cellColor = AppColors.accentIndigo.withValues(alpha: 0.3);
                } else if (mod == 2) {
                  cellColor = AppColors.accentIndigo.withValues(alpha: 0.6);
                } else {
                  cellColor = AppColors.accentIndigo;
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

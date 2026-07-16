import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ai_study_companion/core/theme/app_colors.dart';
import 'package:ai_study_companion/core/widgets/shimmer_card.dart';
import 'package:ai_study_companion/core/widgets/empty_state.dart';
import 'package:ai_study_companion/models/study_stats.dart';
import 'package:ai_study_companion/features/progress/controllers/progress_controller.dart';

/// The Progress Tracker screen.
///
/// Displays a 7-day bar chart, subject distribution pie chart, and study
/// insights card — all driven by [ProgressController].
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  /// Tracks which pie slice is currently touched (-1 = none).
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressController>().loadProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Consumer<ProgressController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const _LoadingShimmer();
          }

          if (controller.errorMessage != null) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              subtitle: controller.errorMessage!,
              action: TextButton.icon(
                onPressed: controller.loadProgress,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            );
          }

          final stats = controller.stats;
          if (stats == null) {
            return const EmptyState(
              icon: Icons.bar_chart_rounded,
              title: 'No data yet',
              subtitle: 'Start studying to see your progress here.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBarChartSection(context, stats),
                const SizedBox(height: 28),
                _buildPieChartSection(context, stats),
                const SizedBox(height: 28),
                _buildInsightsCard(context, stats),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7-Day Study Streak — Bar Chart
  // ---------------------------------------------------------------------------

  Widget _buildBarChartSection(BuildContext context, StudyStats stats) {
    final theme = Theme.of(context);
    final maxHours = stats.weeklyData
        .fold<double>(0, (prev, d) => d.hours > prev ? d.hours : prev);
    // Round up to nearest whole number for y-axis ceiling.
    final yMax = (maxHours + 1).ceilToDouble();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.streakOrange, size: 22),
              const SizedBox(width: 8),
              Text(
                '7-Day Study Streak',
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: yMax,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = stats.weeklyData[group.x.toInt()].day;
                      return BarTooltipItem(
                        '$day\n${rod.toY.toStringAsFixed(1)} hrs',
                        theme.textTheme.bodySmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= stats.weeklyData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            stats.weeklyData[idx].day,
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}h',
                          style: theme.textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.divider.withValues(alpha: 0.6),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(stats.weeklyData.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: stats.weeklyData[i].hours,
                        width: 22,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryLight, AppColors.primary],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: yMax,
                          color: AppColors.surface,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notes by Subject — Pie Chart
  // ---------------------------------------------------------------------------

  Widget _buildPieChartSection(BuildContext context, StudyStats stats) {
    final theme = Theme.of(context);
    final totalNotes =
        stats.subjectDistribution.fold<int>(0, (sum, s) => sum + s.count);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded,
                  color: AppColors.accent, size: 22),
              const SizedBox(width: 8),
              Text(
                'Notes by Subject',
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex = pieTouchResponse
                          .touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 44,
                sections: _buildPieSections(stats, totalNotes),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: stats.subjectDistribution.map((s) {
              return _LegendDot(
                color: s.color,
                label: s.subject,
                count: s.count,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
      StudyStats stats, int totalNotes) {
    return List.generate(stats.subjectDistribution.length, (i) {
      final item = stats.subjectDistribution[i];
      final isTouched = i == _touchedPieIndex;
      final percentage =
          totalNotes > 0 ? (item.count / totalNotes * 100) : 0.0;

      return PieChartSectionData(
        value: item.count.toDouble(),
        color: item.color,
        radius: isTouched ? 60 : 50,
        title: '${percentage.toStringAsFixed(0)}%',
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        titlePositionPercentageOffset: 0.6,
        badgePositionPercentageOffset: 1.0,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Study Insights
  // ---------------------------------------------------------------------------

  Widget _buildInsightsCard(BuildContext context, StudyStats stats) {
    final theme = Theme.of(context);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Study Insights',
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InsightRow(
            emoji: '🔥',
            text:
                "You've maintained a ${stats.currentStreak}-day study streak!",
          ),
          const SizedBox(height: 12),
          _InsightRow(
            emoji: '📝',
            text: 'Total quizzes taken: ${stats.quizzesTaken}',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            emoji: '📚',
            text: 'Most studied subject: ${_getMostStudiedSubject(stats)}',
          ),
          const SizedBox(height: 12),
          _InsightRow(
            emoji: '📖',
            text: 'Notes uploaded: ${stats.notesUploaded}',
          ),
        ],
      ),
    );
  }

  String _getMostStudiedSubject(StudyStats stats) {
    if (stats.subjectDistribution.isEmpty) return 'None';
    final sorted = List<SubjectDistribution>.from(stats.subjectDistribution)
      ..sort((a, b) => b.count.compareTo(a.count));
    return sorted.first.subject;
  }
}

// =============================================================================
// Shared helpers
// =============================================================================

/// A white card wrapper with rounded corners and subtle shadow.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A single insight row with an emoji prefix.
class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.emoji, required this.text});
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}

/// Pie chart legend dot with color, label, and count.
class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.count,
  });
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Shimmer placeholders while progress data loads.
class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          ShimmerCard(height: 280),
          SizedBox(height: 20),
          ShimmerCard(height: 320),
          SizedBox(height: 20),
          ShimmerCard(height: 180),
        ],
      ),
    );
  }
}

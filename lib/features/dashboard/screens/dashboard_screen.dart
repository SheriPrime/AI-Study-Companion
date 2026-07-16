import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:ai_study_companion/core/theme/app_colors.dart';
import 'package:ai_study_companion/core/widgets/stat_card.dart';
import 'package:ai_study_companion/core/widgets/shimmer_card.dart';
import 'package:ai_study_companion/core/widgets/circular_progress_ring.dart';
import 'package:ai_study_companion/features/dashboard/controllers/dashboard_controller.dart';
import 'package:ai_study_companion/features/auth/controllers/auth_controller.dart';
import 'package:ai_study_companion/models/deadline.dart';

/// The main dashboard screen for the AI Study Companion app.
///
/// Displays a personalised greeting, daily study-goal progress ring,
/// quick-stats grid, and upcoming deadline cards. All data is loaded
/// asynchronously via [DashboardController].
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger data load after the first frame so the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().loadDashboard();
    });
  }

  /// Extracts the first name from a full name string.
  String _firstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : 'Student';
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();
    final userName = authController.currentUser?.name ?? 'Student';
    final firstName = _firstName(userName);
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('AI Study Companion'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      firstInitial,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<DashboardController>(
        builder: (context, controller, _) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.loadDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ──────────────────────────────────────────────
                  const SizedBox(height: 8),
                  Text(
                    'Welcome, $firstName! 👋',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Let's make today productive",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),

                  const SizedBox(height: 28),

                  // ── Daily Study Goal ──────────────────────────────────────
                  _buildSectionHeader(context, 'Daily Study Goal'),
                  const SizedBox(height: 16),
                  if (controller.isLoading)
                    const Center(child: ShimmerCard(height: 180))
                  else
                    _buildDailyGoalCard(context, controller),

                  const SizedBox(height: 28),

                  // ── Quick Stats ───────────────────────────────────────────
                  _buildSectionHeader(context, 'Quick Stats'),
                  const SizedBox(height: 16),
                  if (controller.isLoading)
                    _buildStatsShimmer()
                  else
                    _buildStatsGrid(context, controller),

                  const SizedBox(height: 28),

                  // ── Upcoming Deadlines ────────────────────────────────────
                  _buildSectionHeader(context, 'Upcoming Deadlines'),
                  const SizedBox(height: 16),
                  if (controller.isLoading)
                    _buildDeadlinesShimmer()
                  else if (controller.deadlines.isEmpty)
                    _buildEmptyDeadlines(context)
                  else
                    ...controller.deadlines.map(
                      (d) => _buildDeadlineCard(context, d),
                    ),

                  // ── Error Banner ──────────────────────────────────────────
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorBanner(context, controller.errorMessage!),
                  ],

                  // Bottom safe-area breathing room
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Section Header
  // ===========================================================================

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  // ===========================================================================
  // Daily Goal Card
  // ===========================================================================

  Widget _buildDailyGoalCard(
    BuildContext context,
    DashboardController controller,
  ) {
    final progress = controller.stats?.dailyGoalProgress ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          CircularProgressRing(
            progress: progress,
            size: 150,
            strokeWidth: 14,
            label: 'Daily Goal',
            progressColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            _goalMotivation(progress),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Returns an encouraging string based on progress value.
  String _goalMotivation(double progress) {
    if (progress >= 1.0) return "🎉 Goal achieved! Amazing work!";
    if (progress >= 0.75) return "🔥 Almost there — keep pushing!";
    if (progress >= 0.5) return "💪 Halfway done — great momentum!";
    if (progress >= 0.25) return "📖 Good start — keep going!";
    return "🚀 Start studying to hit your daily goal!";
  }

  // ===========================================================================
  // Quick Stats Grid
  // ===========================================================================

  Widget _buildStatsGrid(
    BuildContext context,
    DashboardController controller,
  ) {
    final stats = controller.stats;
    final totalHours = stats?.weeklyData.fold<double>(0.0, (sum, item) => sum + item.hours) ?? 0.0;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          title: 'Streak',
          value: '${stats?.currentStreak ?? 0}',
          icon: Icons.local_fire_department,
          color: AppColors.streakOrange,
        ),
        StatCard(
          title: 'Quizzes',
          value: '${stats?.quizzesTaken ?? 0}',
          icon: Icons.quiz_outlined,
          color: AppColors.quizPurple,
        ),
        StatCard(
          title: 'Notes',
          value: '${stats?.notesUploaded ?? 0}',
          icon: Icons.description_outlined,
          color: AppColors.notesTeal,
        ),
        StatCard(
          title: 'Hours',
          value: totalHours > 0.0 ? totalHours.toStringAsFixed(1) : '0.0',
          icon: Icons.timer_outlined,
          color: AppColors.plannerBlue,
        ),
      ],
    );
  }

  Widget _buildStatsShimmer() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        ShimmerCard(height: 120),
        ShimmerCard(height: 120),
        ShimmerCard(height: 120),
        ShimmerCard(height: 120),
      ],
    );
  }

  // ===========================================================================
  // Deadline Cards
  // ===========================================================================

  Widget _buildDeadlineCard(BuildContext context, Deadline deadline) {
    final daysRemaining = deadline.daysRemaining;
    final isOverdue = deadline.isOverdue;

    // Color logic: overdue → error, ≤ 3 days → warning, else → success
    final Color statusColor;
    if (isOverdue) {
      statusColor = AppColors.error;
    } else if (daysRemaining <= 3) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.success;
    }

    // Human-readable label
    final String daysLabel;
    if (isOverdue) {
      daysLabel = '${daysRemaining.abs()} day${daysRemaining.abs() == 1 ? '' : 's'} overdue';
    } else if (daysRemaining == 0) {
      daysLabel = 'Due today';
    } else if (daysRemaining == 1) {
      daysLabel = 'Due tomorrow';
    } else {
      daysLabel = '$daysRemaining days left';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Leading icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event_outlined,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Title & course
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadline.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  deadline.course,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Days remaining chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daysLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlinesShimmer() {
    return Column(
      children: const [
        ShimmerCard(height: 80),
        SizedBox(height: 12),
        ShimmerCard(height: 80),
        SizedBox(height: 12),
        ShimmerCard(height: 80),
      ],
    );
  }

  Widget _buildEmptyDeadlines(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            'No upcoming deadlines',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'re all caught up! 🎉',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Error Banner
  // ===========================================================================

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

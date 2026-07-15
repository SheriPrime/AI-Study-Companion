import 'package:flutter/foundation.dart';
import 'package:ai_study_companion/models/study_stats.dart';
import 'package:ai_study_companion/core/db/database_helper.dart';
import 'package:ai_study_companion/core/theme/app_colors.dart';

/// Controller for the Progress Tracker feature.
///
/// Loads [StudyStats] from [DatabaseHelper] and exposes reactive
/// state for the progress UI (bar chart, pie chart, insights).
class ProgressController extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  ProgressController(this._dbHelper);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StudyStats? _stats;
  StudyStats? get stats => _stats;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Fetches aggregated study statistics from the SQLite database.
  Future<void> loadProgress() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final notesCount = await _dbHelper.getNotesCount();
      final subjectData = await _dbHelper.getNotesCountBySubject();
      final recentStats = await _dbHelper.getRecentStats(7);

      // Build weekly data
      final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final weeklyData = dayLabels.map((day) {
        return DailyStudyData(day: day, hours: 0.0);
      }).toList();

      // Build subject distribution from actual notes
      final subjectDistribution = subjectData.map((row) {
        final subject = row['subject'] as String;
        final count = row['count'] as int;
        return SubjectDistribution(
          subject: subject,
          count: count,
          color: AppColors.getSubjectColor(subject),
        );
      }).toList();

      // Calculate streak and quizzes
      int streak = 0;
      int quizzesTaken = 0;
      double dailyGoalProgress = 0.0;

      if (recentStats.isNotEmpty) {
        final latest = recentStats.last;
        streak = latest['streak'] as int? ?? 0;
        quizzesTaken = latest['quizzes_taken'] as int? ?? 0;
        dailyGoalProgress = (latest['daily_goal_progress'] as num?)?.toDouble() ?? 0.0;
      }

      _stats = StudyStats(
        currentStreak: streak,
        quizzesTaken: quizzesTaken,
        notesUploaded: notesCount,
        dailyGoalProgress: dailyGoalProgress,
        weeklyData: weeklyData,
        subjectDistribution: subjectDistribution,
      );
    } catch (e) {
      _errorMessage = 'Failed to load progress data. Please try again.';
      debugPrint('ProgressController.loadProgress error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

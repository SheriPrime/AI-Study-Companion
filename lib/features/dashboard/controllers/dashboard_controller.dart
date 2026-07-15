import 'package:flutter/foundation.dart';
import 'package:ai_study_companion/models/study_stats.dart';
import 'package:ai_study_companion/models/deadline.dart';
import 'package:ai_study_companion/core/db/database_helper.dart';
import 'package:ai_study_companion/core/theme/app_colors.dart';

/// Controller for the Dashboard screen.
///
/// Manages loading of study statistics and upcoming deadlines from
/// [DatabaseHelper]. Stats are computed from the local SQLite database.
class DashboardController extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  DashboardController(this._dbHelper);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StudyStats? _stats;
  StudyStats? get stats => _stats;

  List<Deadline> _deadlines = [];
  List<Deadline> get deadlines => _deadlines;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Loads study stats and deadlines.
  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _computeStats(),
        _loadDeadlines(),
      ]);

      _stats = results[0] as StudyStats;
      _deadlines = results[1] as List<Deadline>;
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data. Please try again.';
      debugPrint('DashboardController.loadDashboard error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Computes stats from the database.
  Future<StudyStats> _computeStats() async {
    final notesCount = await _dbHelper.getNotesCount();
    final subjectData = await _dbHelper.getNotesCountBySubject();
    final recentStats = await _dbHelper.getRecentStats(7);

    // Build weekly data from recent stats
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

    // Calculate streak and quizzes from stats table
    int streak = 0;
    int quizzesTaken = 0;
    double dailyGoalProgress = 0.0;

    if (recentStats.isNotEmpty) {
      final latest = recentStats.last;
      streak = latest['streak'] as int? ?? 0;
      quizzesTaken = latest['quizzes_taken'] as int? ?? 0;
      dailyGoalProgress = (latest['daily_goal_progress'] as num?)?.toDouble() ?? 0.0;
    }

    return StudyStats(
      currentStreak: streak,
      quizzesTaken: quizzesTaken,
      notesUploaded: notesCount,
      dailyGoalProgress: dailyGoalProgress,
      weeklyData: weeklyData,
      subjectDistribution: subjectDistribution,
    );
  }

  /// Loads deadlines. For now returns hardcoded deadlines since
  /// the deadline feature doesn't have its own DB table yet.
  Future<List<Deadline>> _loadDeadlines() async {
    // Deadlines remain as sample data for this phase.
    // A deadlines table can be added in a future iteration.
    return [
      Deadline(
        id: 'dl_1',
        title: 'AI Mid-Term Exam',
        course: 'Artificial Intelligence',
        dueDate: DateTime.now().add(const Duration(days: 5)),
      ),
      Deadline(
        id: 'dl_2',
        title: 'OOP Project Submission',
        course: 'Object-Oriented Programming',
        dueDate: DateTime.now().add(const Duration(days: 2)),
      ),
      Deadline(
        id: 'dl_3',
        title: 'DSA Assignment #4',
        course: 'Data Structures',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Deadline(
        id: 'dl_4',
        title: 'Database Lab Report',
        course: 'Database Systems',
        dueDate: DateTime.now().add(const Duration(days: 8)),
      ),
    ];
  }
}

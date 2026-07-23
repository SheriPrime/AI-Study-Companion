import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_study_companion/models/study_stats.dart';
import 'package:ai_study_companion/models/deadline.dart';
import 'package:ai_study_companion/models/study_task.dart';
import 'package:ai_study_companion/core/db/database_helper.dart';
import 'package:ai_study_companion/services/firestore_service.dart';
import 'package:ai_study_companion/core/theme/app_colors.dart';

/// Controller for the Dashboard screen.
///
/// Manages loading of study statistics and upcoming deadlines.
/// Integrates both Firestore and local SQLite data (offline review) for stats.
class DashboardController extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final FirestoreService _firestoreService;

  DashboardController(this._dbHelper, this._firestoreService);

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
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('local_userUid');
    if (uid == null) {
      _errorMessage = 'No user logged in.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _computeStats(uid),
        _loadDeadlines(uid),
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

  /// Computes stats combining SQLite and Firestore.
  Future<StudyStats> _computeStats(String uid) async {
    final notesCount = await _dbHelper.getNotesCount();
    final subjectData = await _dbHelper.getNotesCountBySubject();
    final progressData = await _firestoreService.getProgress(uid);
    final tasks = await _firestoreService.fetchTasks(uid);

    // Build weekly data from real recorded hours or 0.0 for unrecorded days
    final Map<String, dynamic>? hoursMap = progressData != null
        ? progressData['weekly_hours'] as Map<String, dynamic>?
        : null;

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weeklyData = dayLabels.map((day) {
      final hours = hoursMap != null && hoursMap.containsKey(day)
          ? (hoursMap[day] as num).toDouble()
          : 0.0;
      return DailyStudyData(day: day, hours: hours);
    }).toList();

    // Build subject distribution from actual local notes
    final subjectDistribution = subjectData.map((row) {
      final subject = row['subject'] as String;
      final count = row['count'] as int;
      return SubjectDistribution(
        subject: subject,
        count: count,
        color: AppColors.getSubjectColor(subject),
      );
    }).toList();

    // Calculate streak, quizzes, and daily goal progress from real activity
    int streak = 0;
    int quizzesTaken = 0;
    double dailyGoalProgress = 0.0;

    if (progressData != null) {
      streak = progressData['streak'] as int? ?? 0;
      quizzesTaken = progressData['quizzes_taken'] as int? ?? 0;
      dailyGoalProgress = (progressData['daily_goal_progress'] as num?)?.toDouble() ?? 0.0;
    }

    // Compute real daily goal progress based on today's tasks if tasks exist
    final now = DateTime.now();
    final todayTasks = tasks.where((t) {
      final d = t.dueDateTime;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();

    if (todayTasks.isNotEmpty) {
      final completedToday = todayTasks.where((t) => t.status == TaskStatus.done).length;
      dailyGoalProgress = completedToday / todayTasks.length;
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

  /// Loads real-time deadlines from user's active tasks in Firestore/SQLite.
  Future<List<Deadline>> _loadDeadlines(String uid) async {
    try {
      final tasks = await _firestoreService.fetchTasks(uid);
      final activeTasks = tasks.where((t) => t.status != TaskStatus.done).toList();

      if (activeTasks.isNotEmpty) {
        return activeTasks.map((t) {
          return Deadline(
            id: t.id?.toString() ?? t.title,
            title: t.title,
            course: (t.description != null && t.description!.trim().isNotEmpty)
                ? t.description!
                : 'Study Task',
            dueDate: t.dueDateTime,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading live deadlines: $e');
    }

    // Return empty list if no active tasks exist (triggers real empty state UI)
    return [];
  }
}

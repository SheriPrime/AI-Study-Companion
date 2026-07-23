import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_study_companion/models/study_stats.dart';
import 'package:ai_study_companion/core/db/database_helper.dart';
import 'package:ai_study_companion/services/firestore_service.dart';
import 'package:ai_study_companion/core/theme/app_colors.dart';

/// Controller for the Progress Tracker feature.
///
/// Loads [StudyStats] from [DatabaseHelper] and [FirestoreService] and exposes reactive
/// state for the progress UI (bar chart, pie chart, insights).
class ProgressController extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final FirestoreService _firestoreService;

  ProgressController(this._dbHelper, this._firestoreService);

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

  /// Fetches study statistics from both SQLite and Cloud Firestore.
  Future<void> loadProgress() async {
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
      final notesCount = await _dbHelper.getNotesCount();
      final subjectData = await _dbHelper.getNotesCountBySubject();
      final progressData = await _firestoreService.getProgress(uid);

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

      // Calculate streak and progress from Firestore/Local progress tracking
      int streak = 0;
      int quizzesTaken = 0;
      double dailyGoalProgress = 0.0;

      if (progressData != null) {
        streak = progressData['streak'] as int? ?? 0;
        quizzesTaken = progressData['quizzes_taken'] as int? ?? 0;
        dailyGoalProgress = (progressData['daily_goal_progress'] as num?)?.toDouble() ?? 0.0;
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

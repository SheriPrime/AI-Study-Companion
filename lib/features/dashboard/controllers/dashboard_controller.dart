import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_study_companion/models/study_stats.dart';
import 'package:ai_study_companion/models/deadline.dart';
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

  /// Computes stats combining SQLite and Firestore.
  Future<StudyStats> _computeStats(String uid) async {
    final notesCount = await _dbHelper.getNotesCount();
    final subjectData = await _dbHelper.getNotesCountBySubject();
    final progressData = await _firestoreService.getProgress(uid);

    // Build weekly data from Firestore or default baseline
    final Map<String, dynamic>? hoursMap = progressData != null
        ? progressData['weekly_hours'] as Map<String, dynamic>?
        : null;

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final defaultHours = {
      'Mon': 2.5,
      'Tue': 1.8,
      'Wed': 3.2,
      'Thu': 2.0,
      'Fri': 4.1,
      'Sat': 1.5,
      'Sun': 3.0,
    };

    final weeklyData = dayLabels.map((day) {
      final hours = hoursMap != null && hoursMap.containsKey(day)
          ? (hoursMap[day] as num).toDouble()
          : (defaultHours[day] ?? 0.0);
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

    // Calculate streak and progress from Firestore progress collection
    int streak = 1;
    int quizzesTaken = 0;
    double dailyGoalProgress = 0.0;

    if (progressData != null) {
      streak = progressData['streak'] as int? ?? 1;
      quizzesTaken = progressData['quizzes_taken'] as int? ?? 0;
      dailyGoalProgress = (progressData['daily_goal_progress'] as num?)?.toDouble() ?? 0.0;
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

  /// Loads deadlines.
  Future<List<Deadline>> _loadDeadlines() async {
    // Deadlines remain as sample data for this phase as per prompt spec.
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

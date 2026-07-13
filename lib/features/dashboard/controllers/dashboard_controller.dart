import 'package:flutter/foundation.dart';
import 'package:ai_study_companion/services/mock_database_service.dart';
import 'package:ai_study_companion/models/study_stats.dart';
import 'package:ai_study_companion/models/deadline.dart';

/// Controller for the Dashboard screen.
///
/// Manages loading of study statistics and upcoming deadlines from
/// [MockDatabaseService]. Both data sets are fetched concurrently
/// using [Future.wait] to minimise perceived latency.
class DashboardController extends ChangeNotifier {
  final MockDatabaseService _databaseService;

  DashboardController(this._databaseService);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Whether a data load is currently in progress.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Aggregated study statistics (null until first successful load).
  StudyStats? _stats;
  StudyStats? get stats => _stats;

  /// Upcoming assignment / exam deadlines.
  List<Deadline> _deadlines = [];
  List<Deadline> get deadlines => _deadlines;

  /// Human-readable error message, if the last load failed.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Loads study stats and deadlines concurrently.
  ///
  /// Sets [isLoading] to `true` before starting, and `false` once complete.
  /// On failure, [errorMessage] is populated with a user-friendly message.
  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _databaseService.getStudyStats(),
        _databaseService.getDeadlines(),
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
}

import 'package:flutter/foundation.dart';
import 'package:ai_study_companion/models/study_stats.dart';
import 'package:ai_study_companion/services/mock_database_service.dart';

/// Controller for the Progress Tracker feature.
///
/// Loads [StudyStats] from [MockDatabaseService] and exposes reactive
/// state for the progress UI (bar chart, pie chart, insights).
class ProgressController extends ChangeNotifier {
  final MockDatabaseService _databaseService;

  ProgressController(this._databaseService);

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

  /// Fetches aggregated study statistics from the mock service.
  Future<void> loadProgress() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _databaseService.getStudyStats();
    } catch (e) {
      _errorMessage = 'Failed to load progress data. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

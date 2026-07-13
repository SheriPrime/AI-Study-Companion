import 'package:flutter/foundation.dart';
import 'package:ai_study_companion/models/study_task.dart';
import 'package:ai_study_companion/services/mock_database_service.dart';

/// Controller for the Study Planner feature.
///
/// Manages loading, adding, and toggling [StudyTask] items via
/// [MockDatabaseService]. Exposes filtered getters for UI sections.
class PlannerController extends ChangeNotifier {
  final MockDatabaseService _databaseService;

  PlannerController(this._databaseService);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<StudyTask> _tasks = [];
  List<StudyTask> get tasks => List.unmodifiable(_tasks);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isAddingTask = false;
  bool get isAddingTask => _isAddingTask;

  // ---------------------------------------------------------------------------
  // Filtered getters
  // ---------------------------------------------------------------------------

  /// Tasks whose status is [TaskStatus.overdue].
  List<StudyTask> get overdueTasks =>
      _tasks.where((t) => t.status == TaskStatus.overdue).toList();

  /// Tasks whose status is [TaskStatus.pending].
  List<StudyTask> get pendingTasks =>
      _tasks.where((t) => t.status == TaskStatus.pending).toList();

  /// Tasks whose status is [TaskStatus.done].
  List<StudyTask> get doneTasks =>
      _tasks.where((t) => t.status == TaskStatus.done).toList();

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Loads all tasks from the mock service and sorts by date ascending.
  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _databaseService.getTasks();
      loaded.sort((a, b) => a.date.compareTo(b.date));
      _tasks = loaded;
    } catch (e) {
      _errorMessage = 'Failed to load tasks. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new [StudyTask] via the mock service and refreshes the list.
  Future<void> addTask(StudyTask task) async {
    _isAddingTask = true;
    notifyListeners();

    try {
      await _databaseService.addTask(task);
      _tasks.add(task);
      _tasks.sort((a, b) => a.date.compareTo(b.date));
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to add task. Please try again.';
    } finally {
      _isAddingTask = false;
      notifyListeners();
    }
  }

  /// Toggles a task between pending ↔ done via the mock service.
  Future<void> toggleTask(String id) async {
    try {
      await _databaseService.toggleTaskStatus(id);
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final task = _tasks[index];
        task.status = task.status == TaskStatus.done
            ? TaskStatus.pending
            : TaskStatus.done;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update task.';
      notifyListeners();
    }
  }
}

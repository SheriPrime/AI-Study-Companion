import 'package:flutter/foundation.dart';
import 'package:ai_study_companion/models/study_task.dart';
import 'package:ai_study_companion/core/db/database_helper.dart';

/// Controller for the Study Planner feature.
///
/// Manages loading, adding, and toggling [StudyTask] items via
/// [DatabaseHelper]. Exposes filtered getters for UI sections.
class PlannerController extends ChangeNotifier {
  final DatabaseHelper _dbHelper;

  PlannerController(this._dbHelper);

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

  /// Loads all tasks from the SQLite database and sorts by date ascending.
  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _dbHelper.fetchTasks();
      _tasks = rows.map((row) => StudyTask.fromMap(row)).toList();
      _tasks.sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      _errorMessage = 'Failed to load tasks. Please try again.';
      debugPrint('PlannerController.loadTasks error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new [StudyTask] to the SQLite database and refreshes the list.
  Future<void> addTask(StudyTask task) async {
    _isAddingTask = true;
    notifyListeners();

    try {
      final id = await _dbHelper.insertTask(task.toMap());
      final savedTask = task.copyWith(id: id);
      _tasks.add(savedTask);
      _tasks.sort((a, b) => a.date.compareTo(b.date));
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to add task. Please try again.';
      debugPrint('PlannerController.addTask error: $e');
    } finally {
      _isAddingTask = false;
      notifyListeners();
    }
  }

  /// Toggles a task between pending ↔ done via SQLite.
  Future<void> toggleTask(int id) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final task = _tasks[index];
        final newStatus = task.status == TaskStatus.done
            ? TaskStatus.pending
            : TaskStatus.done;
        final statusStr = newStatus == TaskStatus.done ? 'Done' : 'Pending';
        await _dbHelper.updateTaskStatus(id, statusStr);
        task.status = newStatus;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update task.';
      notifyListeners();
    }
  }
}

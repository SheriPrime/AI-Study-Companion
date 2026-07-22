import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_study_companion/models/study_task.dart';
import 'package:ai_study_companion/services/firestore_service.dart';
import 'package:ai_study_companion/services/notification_service.dart';
import 'package:intl/intl.dart';

/// Controller for the Study Planner feature.
///
/// Manages loading, adding, and toggling [StudyTask] items via [FirestoreService].
class PlannerController extends ChangeNotifier {
  final FirestoreService _firestoreService;

  PlannerController(this._firestoreService);

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

  /// Loads all tasks from the Firestore database and sorts by date ascending.
  Future<void> loadTasks() async {
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
      _tasks = await _firestoreService.fetchTasks(uid);
      _tasks.sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      _errorMessage = 'Failed to load tasks. Please try again.';
      debugPrint('PlannerController.loadTasks error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new [StudyTask] to Firestore and refreshes the local list.
  Future<void> addTask(StudyTask task) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('local_userUid');
    if (uid == null) return;

    _isAddingTask = true;
    notifyListeners();

    try {
      final generatedId = await _firestoreService.insertTask(uid, task);
      final savedTask = task.copyWith(id: generatedId);
      _tasks.add(savedTask);
      _tasks.sort((a, b) => a.date.compareTo(b.date));
      _errorMessage = null;

      // ── Trigger Immediate Notification ───────────────────────────────
      final notifService = NotificationService();
      final immediateId = generatedId.hashCode;
      final formattedDate = DateFormat('MMM d, h:mm a').format(task.dueDateTime);
      await notifService.showImmediateNotification(
        id: immediateId,
        title: 'Task Added! 📅',
        body: '"${task.title}" is set for $formattedDate.',
      );

      // ── Schedule Reminder at 5:00 PM the previous day ──────────────────
      final previousDay = task.dueDateTime.subtract(const Duration(days: 1));
      final reminderTime = DateTime(
        previousDay.year,
        previousDay.month,
        previousDay.day,
        17, // 5:00 PM (17:00)
        0,
      );

      final reminderId = generatedId.hashCode + 1;
      await notifService.scheduleNotification(
        id: reminderId,
        title: 'Task Due Tomorrow! ⏳',
        body: '"${task.title}" is due tomorrow at ${DateFormat('h:mm a').format(task.dueDateTime)}.',
        scheduledDateTime: reminderTime,
      );
    } catch (e) {
      _errorMessage = 'Failed to add task. Please try again.';
      debugPrint('PlannerController.addTask error: $e');
    } finally {
      _isAddingTask = false;
      notifyListeners();
    }
  }

  /// Toggles a task status in Firestore and updates the local state.
  Future<void> toggleTask(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('local_userUid');
    if (uid == null) return;

    try {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final task = _tasks[index];
        final newStatus = task.status == TaskStatus.done
            ? TaskStatus.pending
            : TaskStatus.done;
        final statusStr = newStatus == TaskStatus.done ? 'Done' : 'Pending';

        await _firestoreService.updateTaskStatus(uid, task.title, task.date, statusStr);
        task.status = newStatus;
        notifyListeners();

        // If the task was completed, cancel any scheduled tomorrow-reminder alarm
        if (newStatus == TaskStatus.done) {
          final reminderId = id.hashCode + 1;
          await NotificationService().cancelNotification(reminderId);
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to update task.';
      notifyListeners();
    }
  }

  /// Deletes a task by id from Firestore/SQLite and cancels its notifications.
  Future<bool> deleteTask(int id, String taskTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('local_userUid');
    if (uid == null) return false;

    try {
      await _firestoreService.deleteTask(uid, id, taskTitle);
      
      // Cancel notifications
      final notifService = NotificationService();
      await notifService.cancelNotification(id.hashCode);
      await notifService.cancelNotification(id.hashCode + 1);

      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete task.';
      notifyListeners();
      return false;
    }
  }
}

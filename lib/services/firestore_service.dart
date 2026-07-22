import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_study_companion/models/study_task.dart';
import 'package:ai_study_companion/core/db/database_helper.dart';

/// Service interfacing with Cloud Firestore, with an offline SQLite / SharedPreferences fallback.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Determines if the service is in offline Developer Fallback Mode.
  bool get isFallbackMode {
    try {
      return FirebaseAuth.instance.app.options.apiKey == "placeholder-api-key-ai-study-companion";
    } catch (_) {
      return true;
    }
  }

  // ─── User Profile Collections ──────────────────────────────────────────

  /// Creates a user profile document in Firestore on registration.
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String university,
    required String department,
    required String timeline,
  }) async {
    if (isFallbackMode) return;

    await _db.collection('users').doc(uid).set({
      'name': name,
      'university': university,
      'department': department,
      'timeline': timeline,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Initialize progress stats too
    await _db.collection('progress').doc(uid).set({
      'streak': 1,
      'quizzes_taken': 0,
      'daily_goal_progress': 0.0,
      'lastActive': FieldValue.serverTimestamp(),
    });

    // Add default courses
    final defaultCourses = ['AI', 'OOP', 'DSA', 'DB', 'OS'];
    final batch = _db.batch();
    for (final course in defaultCourses) {
      final ref = _db.collection('courses').doc('${uid}_$course');
      batch.set(ref, {
        'userId': uid,
        'name': course,
      });
    }
    await batch.commit();
  }

  /// Retrieves profile metadata for the given user [uid].
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    if (isFallbackMode) {
      return {
        'name': 'Student',
        'university': 'COMSATS University Islamabad (Offline)',
        'department': 'BSCS',
        'timeline': '2023–2027',
      };
    }

    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ─── Study Planner Tasks ───────────────────────────────────────────────

  /// Fetches all planner tasks for the logged in user.
  Future<List<StudyTask>> fetchTasks(String uid) async {
    if (isFallbackMode) {
      final rows = await _dbHelper.fetchTasks();
      final tasks = rows.map((row) => StudyTask.fromMap(row)).toList();
      return tasks;
    }

    final snapshot = await _db
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final map = {
        'id': doc.id.hashCode,
        'title': data['title'] as String? ?? '',
        'description': data['description'] as String?,
        'date': data['date'] as String? ?? DateTime.now().toIso8601String(),
        'time': data['time'] as String?,
        'status': data['status'] as String? ?? 'Pending',
      };
      return StudyTask.fromMap(map);
    }).toList();
  }

  /// Inserts a task tied to the user's UID.
  Future<int> insertTask(String uid, StudyTask task) async {
    if (isFallbackMode) {
      return await _dbHelper.insertTask(task.toMap());
    }

    final docRef = await _db.collection('tasks').add({
      'userId': uid,
      'title': task.title,
      'description': task.description,
      'date': task.date.toIso8601String(),
      'time': task.time != null
          ? '${task.time!.hour.toString().padLeft(2, '0')}:${task.time!.minute.toString().padLeft(2, '0')}'
          : null,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id.hashCode;
  }

  /// Updates a task's status.
  Future<void> updateTaskStatus(String uid, String taskTitle, DateTime taskDate, String status) async {
    if (isFallbackMode) {
      // Find local task in SQLite by matching title
      final rows = await _dbHelper.fetchTasks();
      for (final row in rows) {
        if (row['title'] == taskTitle) {
          final id = row['id'] as int;
          await _dbHelper.updateTaskStatus(id, status);
          break;
        }
      }
      return;
    }

    final snapshot = await _db
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .where('title', isEqualTo: taskTitle)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'status': status,
      });
    }
  }

  /// Deletes a task from Firestore or local SQLite fallback database.
  Future<void> deleteTask(String uid, int taskId, String taskTitle) async {
    if (isFallbackMode) {
      await _dbHelper.deleteTask(taskId);
      return;
    }

    final snapshot = await _db
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .where('title', isEqualTo: taskTitle)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }
  }

  // ─── Progress Tracking ─────────────────────────────────────────────────

  /// Fetches progress metrics for a user.
  Future<Map<String, dynamic>?> getProgress(String uid) async {
    if (isFallbackMode) {
      final prefs = await SharedPreferences.getInstance();
      return {
        'streak': prefs.getInt('local_streak') ?? 7,
        'quizzes_taken': prefs.getInt('local_quizzes') ?? 12,
        'daily_goal_progress': prefs.getDouble('local_goal') ?? 0.72,
      };
    }

    final doc = await _db.collection('progress').doc(uid).get();
    return doc.data();
  }

  /// Updates user streak or daily goal progress.
  Future<void> updateProgress(String uid, {int? streak, int? quizzesTaken, double? dailyGoalProgress}) async {
    if (isFallbackMode) {
      final prefs = await SharedPreferences.getInstance();
      if (streak != null) await prefs.setInt('local_streak', streak);
      if (quizzesTaken != null) await prefs.setInt('local_quizzes', quizzesTaken);
      if (dailyGoalProgress != null) await prefs.setDouble('local_goal', dailyGoalProgress);
      return;
    }

    final Map<String, dynamic> updates = {
      'lastActive': FieldValue.serverTimestamp(),
    };
    if (streak != null) updates['streak'] = streak;
    if (quizzesTaken != null) updates['quizzes_taken'] = quizzesTaken;
    if (dailyGoalProgress != null) updates['daily_goal_progress'] = dailyGoalProgress;

    await _db.collection('progress').doc(uid).set(updates, SetOptions(merge: true));
  }

  // ─── Dynamic Courses ───────────────────────────────────────────────────

  /// Fetches custom courses added by the user.
  Future<List<String>> fetchCourses(String uid) async {
    if (isFallbackMode) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('local_courses') ?? ['AI', 'OOP', 'DSA', 'DB', 'OS'];
      return list..sort();
    }

    final snapshot = await _db
        .collection('courses')
        .where('userId', isEqualTo: uid)
        .get();

    final list = snapshot.docs.map((doc) => doc.data()['name'] as String? ?? '').toList();
    return list.where((name) => name.isNotEmpty).toList()..sort();
  }

  /// Adds a custom course for the user.
  Future<void> addCourse(String uid, String courseName) async {
    if (isFallbackMode) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('local_courses') ?? ['AI', 'OOP', 'DSA', 'DB', 'OS'];
      if (!list.contains(courseName)) {
        list.add(courseName);
        await prefs.setStringList('local_courses', list);
      }
      return;
    }

    final docId = '${uid}_$courseName';
    await _db.collection('courses').doc(docId).set({
      'userId': uid,
      'name': courseName,
    });
  }
}

import 'package:flutter/material.dart';
import 'package:ai_study_companion/models/note.dart';
import 'package:ai_study_companion/models/deadline.dart';
import 'package:ai_study_companion/models/study_task.dart';
import 'package:ai_study_companion/models/study_stats.dart';
import 'package:ai_study_companion/core/theme/app_colors.dart';

/// Mock database service simulating SQLite operations with network-like latency.
class MockDatabaseService {
  final List<Note> _notes = [
    Note(
      id: 'note_1',
      title: 'Introduction to Artificial Intelligence',
      subject: 'AI',
      fileName: 'ai_intro.pdf',
      dateAdded: DateTime.now().subtract(const Duration(days: 5)),
      pageCount: 42,
    ),
    Note(
      id: 'note_2',
      title: 'Object-Oriented Design Patterns',
      subject: 'OOP',
      fileName: 'oop_patterns.pdf',
      dateAdded: DateTime.now().subtract(const Duration(days: 3)),
      pageCount: 28,
    ),
    Note(
      id: 'note_3',
      title: 'Data Structures & Algorithms',
      subject: 'DSA',
      fileName: 'dsa_notes.pdf',
      dateAdded: DateTime.now().subtract(const Duration(days: 7)),
      pageCount: 56,
    ),
    Note(
      id: 'note_4',
      title: 'Database Normalization',
      subject: 'DB',
      fileName: 'db_normalization.pdf',
      dateAdded: DateTime.now().subtract(const Duration(days: 1)),
      pageCount: 18,
    ),
    Note(
      id: 'note_5',
      title: 'Neural Networks & Deep Learning',
      subject: 'AI',
      fileName: 'neural_networks.pdf',
      dateAdded: DateTime.now().subtract(const Duration(days: 2)),
      pageCount: 64,
    ),
    Note(
      id: 'note_6',
      title: 'Operating System Concepts',
      subject: 'OS',
      fileName: 'os_concepts.pdf',
      dateAdded: DateTime.now().subtract(const Duration(days: 10)),
      pageCount: 35,
    ),
  ];

  final List<StudyTask> _tasks = [
    StudyTask(
      id: 'task_1',
      title: 'Review AI Chapter 5',
      description: 'Focus on search algorithms and heuristics',
      date: DateTime.now().add(const Duration(days: 1)),
      time: const TimeOfDay(hour: 14, minute: 0),
      status: TaskStatus.pending,
    ),
    StudyTask(
      id: 'task_2',
      title: 'Complete OOP Assignment',
      description: 'Submit design patterns exercise',
      date: DateTime.now().subtract(const Duration(days: 1)),
      time: const TimeOfDay(hour: 23, minute: 59),
      status: TaskStatus.overdue,
    ),
    StudyTask(
      id: 'task_3',
      title: 'Practice DSA Problems',
      description: 'Solve 5 LeetCode problems on trees',
      date: DateTime.now(),
      time: const TimeOfDay(hour: 10, minute: 0),
      status: TaskStatus.done,
    ),
    StudyTask(
      id: 'task_4',
      title: 'DB Quiz Preparation',
      description: 'Review normalization and ER diagrams',
      date: DateTime.now().add(const Duration(days: 2)),
      time: const TimeOfDay(hour: 16, minute: 30),
      status: TaskStatus.pending,
    ),
    StudyTask(
      id: 'task_5',
      title: 'Read OS Chapter 3',
      description: 'Process management and scheduling',
      date: DateTime.now().add(const Duration(days: 3)),
      time: const TimeOfDay(hour: 9, minute: 0),
      status: TaskStatus.pending,
    ),
  ];

  /// Fetches all notes with simulated latency.
  Future<List<Note>> getNotes() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return List.unmodifiable(_notes);
  }

  /// Fetches upcoming deadlines with simulated latency.
  Future<List<Deadline>> getDeadlines() async {
    await Future.delayed(const Duration(seconds: 1));
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

  /// Fetches study planner tasks.
  Future<List<StudyTask>> getTasks() async {
    await Future.delayed(const Duration(seconds: 1));
    return List.from(_tasks);
  }

  /// Fetches aggregated study statistics.
  Future<StudyStats> getStudyStats() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return StudyStats(
      currentStreak: 7,
      quizzesTaken: 12,
      notesUploaded: _notes.length,
      dailyGoalProgress: 0.72,
      weeklyData: const [
        DailyStudyData(day: 'Mon', hours: 2.5),
        DailyStudyData(day: 'Tue', hours: 1.8),
        DailyStudyData(day: 'Wed', hours: 3.2),
        DailyStudyData(day: 'Thu', hours: 2.0),
        DailyStudyData(day: 'Fri', hours: 4.1),
        DailyStudyData(day: 'Sat', hours: 1.5),
        DailyStudyData(day: 'Sun', hours: 3.0),
      ],
      subjectDistribution: [
        SubjectDistribution(subject: 'AI', count: 2, color: AppColors.subjectColors['AI']!),
        SubjectDistribution(subject: 'OOP', count: 1, color: AppColors.subjectColors['OOP']!),
        SubjectDistribution(subject: 'DSA', count: 1, color: AppColors.subjectColors['DSA']!),
        SubjectDistribution(subject: 'DB', count: 1, color: AppColors.subjectColors['DB']!),
        SubjectDistribution(subject: 'OS', count: 1, color: AppColors.subjectColors['OS']!),
      ],
    );
  }

  /// Adds a new task to the planner.
  Future<void> addTask(StudyTask task) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _tasks.add(task);
  }

  /// Toggles a task's status between pending and done.
  Future<void> toggleTaskStatus(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].status = _tasks[index].status == TaskStatus.done
          ? TaskStatus.pending
          : TaskStatus.done;
    }
  }

  /// Simulates uploading a new note.
  Future<Note> uploadNote(String title, String subject, String fileName) async {
    await Future.delayed(const Duration(seconds: 2));
    final note = Note(
      id: 'note_${_notes.length + 1}',
      title: title,
      subject: subject,
      fileName: fileName,
      dateAdded: DateTime.now(),
      pageCount: 24,
    );
    _notes.add(note);
    return note;
  }
}

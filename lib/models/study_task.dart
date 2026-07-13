import 'package:flutter/material.dart';

/// Status of a study planner task.
enum TaskStatus { pending, done, overdue }

/// Represents a task in the study planner.
class StudyTask {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay? time;
  TaskStatus status;

  StudyTask({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    this.status = TaskStatus.pending,
  });

  /// Creates a copy with modified fields.
  StudyTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    TaskStatus? status,
  }) {
    return StudyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}

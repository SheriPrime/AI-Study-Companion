import 'package:flutter/material.dart';

/// Status of a study planner task.
enum TaskStatus { pending, done, overdue }

/// Represents a task in the study planner.
class StudyTask {
  final int? id;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay? time;
  TaskStatus status;

  StudyTask({
    this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    this.status = TaskStatus.pending,
  });

  /// Creates a [StudyTask] from a SQLite row map.
  factory StudyTask.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'Pending';
    TaskStatus status;
    switch (statusStr) {
      case 'Done':
        status = TaskStatus.done;
        break;
      case 'Overdue':
        status = TaskStatus.overdue;
        break;
      default:
        status = TaskStatus.pending;
    }

    return StudyTask(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] != null ? _parseTime(map['time'] as String) : null,
      status: status,
    );
  }

  /// Converts this [StudyTask] to a map for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time != null
          ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
          : null,
      'status': _statusToString(status),
    };
  }

  /// Creates a copy with modified fields.
  StudyTask copyWith({
    int? id,
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

  static String _statusToString(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.overdue:
        return 'Overdue';
    }
  }

  static TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

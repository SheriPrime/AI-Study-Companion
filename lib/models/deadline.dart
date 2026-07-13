/// Represents an upcoming assignment or exam deadline.
class Deadline {
  final String id;
  final String title;
  final String course;
  final DateTime dueDate;

  const Deadline({
    required this.id,
    required this.title,
    required this.course,
    required this.dueDate,
  });

  /// Whether this deadline has passed.
  bool get isOverdue => dueDate.isBefore(DateTime.now());

  /// Days remaining (negative if overdue).
  int get daysRemaining => dueDate.difference(DateTime.now()).inDays;
}

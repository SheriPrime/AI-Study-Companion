import 'dart:ui';

/// Aggregated study statistics for the progress tracker.
class StudyStats {
  final int currentStreak;
  final int quizzesTaken;
  final int notesUploaded;
  final double dailyGoalProgress;
  final List<DailyStudyData> weeklyData;
  final List<SubjectDistribution> subjectDistribution;

  const StudyStats({
    required this.currentStreak,
    required this.quizzesTaken,
    required this.notesUploaded,
    required this.dailyGoalProgress,
    required this.weeklyData,
    required this.subjectDistribution,
  });
}

/// Study hours for a single day (used in bar chart).
class DailyStudyData {
  final String day;
  final double hours;

  const DailyStudyData({required this.day, required this.hours});
}

/// Note count per subject (used in pie chart).
class SubjectDistribution {
  final String subject;
  final int count;
  final Color color;

  const SubjectDistribution({
    required this.subject,
    required this.count,
    required this.color,
  });
}

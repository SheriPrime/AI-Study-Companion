/// AI-generated quiz from a study note.
class Quiz {
  final String noteTitle;
  final List<QuizQuestion> questions;

  const Quiz({
    required this.noteTitle,
    required this.questions,
  });
}

/// A single multiple-choice question in a quiz.
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

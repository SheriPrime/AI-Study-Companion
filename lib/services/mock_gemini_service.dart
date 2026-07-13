import 'package:ai_study_companion/models/summary.dart';
import 'package:ai_study_companion/models/quiz.dart';

/// Mock Gemini AI service simulating summary and quiz generation.
class MockGeminiService {
  /// Generates a mock AI summary for a note (3-second delay).
  Future<Summary> generateSummary(String noteId) async {
    await Future.delayed(const Duration(seconds: 3));
    return const Summary(
      noteTitle: 'Introduction to Artificial Intelligence',
      overview:
          'Artificial Intelligence (AI) is a branch of computer science that aims to '
          'create intelligent machines capable of performing tasks that typically require '
          'human intelligence. This includes learning, reasoning, problem-solving, '
          'perception, and language understanding. The field has evolved from symbolic AI '
          'approaches to modern machine learning and deep learning paradigms that leverage '
          'large datasets and powerful computational resources.',
      keyPoints: [
        'AI can be categorized into Narrow AI (task-specific) and General AI (human-level reasoning)',
        'Machine Learning is a subset of AI that enables systems to learn from data without explicit programming',
        'Search algorithms (BFS, DFS, A*) are fundamental to AI problem-solving',
        'Knowledge representation allows AI systems to store and reason about the world',
        'Natural Language Processing (NLP) enables machines to understand and generate human language',
        'Neural networks are inspired by biological brain structures and form the basis of deep learning',
      ],
      definitions: [
        Definition(
          term: 'Artificial Intelligence',
          meaning:
              'The simulation of human intelligence processes by computer systems, '
              'including learning, reasoning, and self-correction.',
        ),
        Definition(
          term: 'Machine Learning',
          meaning:
              'A subset of AI that provides systems the ability to automatically learn '
              'and improve from experience without being explicitly programmed.',
        ),
        Definition(
          term: 'Heuristic',
          meaning:
              'A problem-solving approach that employs a practical method that is not '
              'guaranteed to be optimal but is sufficient for reaching an immediate goal.',
        ),
        Definition(
          term: 'Neural Network',
          meaning:
              'A computing system inspired by biological neural networks, consisting of '
              'interconnected nodes (neurons) that process information using connectionist approaches.',
        ),
      ],
    );
  }

  /// Generates a mock AI quiz for a note (3-second delay).
  Future<Quiz> generateQuiz(String noteId) async {
    await Future.delayed(const Duration(seconds: 3));
    return const Quiz(
      noteTitle: 'Introduction to Artificial Intelligence',
      questions: [
        QuizQuestion(
          question: 'What is the primary goal of Artificial Intelligence?',
          options: [
            'To replace all human workers',
            'To create machines that can perform tasks requiring human intelligence',
            'To build faster computers',
            'To develop new programming languages',
          ],
          correctIndex: 1,
        ),
        QuizQuestion(
          question: 'Which search algorithm uses a heuristic function to estimate the cost to the goal?',
          options: [
            'Breadth-First Search (BFS)',
            'Depth-First Search (DFS)',
            'A* Search',
            'Uniform Cost Search',
          ],
          correctIndex: 2,
        ),
        QuizQuestion(
          question: 'Machine Learning is best described as:',
          options: [
            'A type of database management system',
            'A subset of AI that learns from data without explicit programming',
            'A programming language for AI',
            'A hardware component for AI systems',
          ],
          correctIndex: 1,
        ),
        QuizQuestion(
          question: 'What are Neural Networks inspired by?',
          options: [
            'Computer circuits',
            'Mathematical equations',
            'Biological brain structures',
            'Internet protocols',
          ],
          correctIndex: 2,
        ),
        QuizQuestion(
          question: 'Which type of AI is designed for a specific task only?',
          options: [
            'General AI',
            'Super AI',
            'Narrow AI',
            'Broad AI',
          ],
          correctIndex: 2,
        ),
      ],
    );
  }
}

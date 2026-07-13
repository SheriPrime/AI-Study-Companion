import 'package:flutter/foundation.dart' hide Summary;
import 'package:ai_study_companion/models/summary.dart';
import 'package:ai_study_companion/models/quiz.dart';
import 'package:ai_study_companion/services/mock_gemini_service.dart';

/// Controller for the AI Hub (note detail) screen.
///
/// Manages AI summary generation, quiz generation, answer tracking,
/// scoring and result display via [MockGeminiService].
class AiHubController extends ChangeNotifier {
  final MockGeminiService _geminiService;

  AiHubController(this._geminiService);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _isGeneratingSummary = false;
  bool get isGeneratingSummary => _isGeneratingSummary;

  bool _isGeneratingQuiz = false;
  bool get isGeneratingQuiz => _isGeneratingQuiz;

  Summary? _summary;
  Summary? get summary => _summary;

  Quiz? _quiz;
  Quiz? get quiz => _quiz;

  /// Maps question index → selected option index.
  final Map<int, int> _selectedAnswers = {};
  Map<int, int> get selectedAnswers => Map.unmodifiable(_selectedAnswers);

  bool _showResults = false;
  bool get showResults => _showResults;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // Derived getters
  // ---------------------------------------------------------------------------

  /// Number of correctly answered questions.
  int get score {
    if (_quiz == null) return 0;
    int correct = 0;
    for (final entry in _selectedAnswers.entries) {
      if (entry.key < _quiz!.questions.length &&
          _quiz!.questions[entry.key].correctIndex == entry.value) {
        correct++;
      }
    }
    return correct;
  }

  /// Whether every question has been answered.
  bool get allAnswered {
    if (_quiz == null) return false;
    return _selectedAnswers.length == _quiz!.questions.length;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Generates an AI summary for the given [noteId].
  Future<void> generateSummary(String noteId) async {
    _isGeneratingSummary = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _geminiService.generateSummary(noteId);
    } catch (e) {
      _errorMessage = 'Failed to generate summary. Please try again.';
    } finally {
      _isGeneratingSummary = false;
      notifyListeners();
    }
  }

  /// Generates an AI quiz for the given [noteId].
  Future<void> generateQuiz(String noteId) async {
    _isGeneratingQuiz = true;
    _errorMessage = null;
    _selectedAnswers.clear();
    _showResults = false;
    notifyListeners();

    try {
      _quiz = await _geminiService.generateQuiz(noteId);
    } catch (e) {
      _errorMessage = 'Failed to generate quiz. Please try again.';
    } finally {
      _isGeneratingQuiz = false;
      notifyListeners();
    }
  }

  /// Records the user's selected [optionIndex] for [questionIndex].
  void selectAnswer(int questionIndex, int optionIndex) {
    if (_showResults) return; // locked after submission
    _selectedAnswers[questionIndex] = optionIndex;
    notifyListeners();
  }

  /// Submits the quiz and reveals correct/incorrect answers.
  void submitQuiz() {
    _showResults = true;
    notifyListeners();
  }

  /// Clears quiz answers and results for a retake.
  void resetQuiz() {
    _selectedAnswers.clear();
    _showResults = false;
    notifyListeners();
  }

  /// Clears both summary and quiz state entirely.
  void resetAll() {
    _summary = null;
    _quiz = null;
    _selectedAnswers.clear();
    _showResults = false;
    _errorMessage = null;
    notifyListeners();
  }
}

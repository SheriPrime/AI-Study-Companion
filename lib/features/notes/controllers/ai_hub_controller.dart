import 'package:flutter/foundation.dart' hide Summary;
import 'package:ai_study_companion/models/summary.dart';
import 'package:ai_study_companion/models/quiz.dart';
import 'package:ai_study_companion/services/gemini_service.dart';
import 'package:ai_study_companion/services/local_file_service.dart';

/// Controller for the AI Hub (note detail) screen.
///
/// Manages AI summary generation, quiz generation, answer tracking,
/// scoring and result display via [GeminiService] and [LocalFileService].
class AiHubController extends ChangeNotifier {
  final GeminiService _geminiService;
  final LocalFileService _fileService;

  AiHubController(this._geminiService, this._fileService);

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

  /// Raw markdown summary from the API.
  String? _markdownSummary;
  String? get markdownSummary => _markdownSummary;

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

  /// Generates an AI summary for the note at [localFilePath].
  ///
  /// 1. Extracts text from the PDF
  /// 2. Sends to Gemini for summarization
  /// 3. Parses the markdown response into a [Summary] model
  Future<void> generateSummary(String localFilePath) async {
    _isGeneratingSummary = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Extract text from PDF
      final extractedText = await _fileService.extractTextFromPDF(localFilePath);

      // Generate summary via Gemini
      final markdown = await _geminiService.generateSummary(extractedText);
      _markdownSummary = markdown;

      // Parse markdown into structured Summary model
      _summary = _parseSummaryFromMarkdown(markdown);
    } on AIException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to generate summary. Please try again.';
      debugPrint('AiHubController.generateSummary error: $e');
    } finally {
      _isGeneratingSummary = false;
      notifyListeners();
    }
  }

  /// Generates an AI quiz for the note at [localFilePath].
  ///
  /// 1. Extracts text from the PDF
  /// 2. Sends to Gemini for quiz generation
  /// 3. Parses the JSON response into [QuizQuestion] models
  Future<void> generateQuiz(String localFilePath) async {
    _isGeneratingQuiz = true;
    _errorMessage = null;
    _selectedAnswers.clear();
    _showResults = false;
    notifyListeners();

    try {
      // Extract text from PDF
      final extractedText = await _fileService.extractTextFromPDF(localFilePath);

      // Generate quiz via Gemini
      final questions = await _geminiService.generateQuiz(extractedText);

      _quiz = Quiz(
        noteTitle: '',
        questions: questions,
      );
    } on AIException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to generate quiz. Please try again.';
      debugPrint('AiHubController.generateQuiz error: $e');
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
    _markdownSummary = null;
    _quiz = null;
    _selectedAnswers.clear();
    _showResults = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Parses a Markdown summary string into a structured [Summary].
  Summary _parseSummaryFromMarkdown(String markdown) {
    final lines = markdown.split('\n').map((l) => l.trim()).toList();

    String overview = '';
    List<String> keyPoints = [];
    List<Definition> definitions = [];

    // Simple state-machine parser
    String currentSection = 'overview';
    final overviewBuffer = StringBuffer();

    for (final line in lines) {
      if (line.isEmpty) continue;

      // Detect section headers
      final lower = line.toLowerCase();
      if (lower.contains('key concept') || lower.contains('key point')) {
        currentSection = 'keyPoints';
        continue;
      }
      if (lower.contains('definition') || lower.contains('crucial')) {
        currentSection = 'definitions';
        continue;
      }

      // Skip markdown headers
      if (line.startsWith('#')) {
        if (currentSection == 'overview' && overviewBuffer.isEmpty) continue;
        continue;
      }

      switch (currentSection) {
        case 'overview':
          if (!line.startsWith('*') && !line.startsWith('-') && !line.startsWith('•')) {
            overviewBuffer.writeln(line);
          } else {
            // First bullet encountered → switch to key points
            currentSection = 'keyPoints';
            final cleaned = line.replaceFirst(RegExp(r'^[\*\-•]\s*'), '').replaceAll('**', '');
            if (cleaned.isNotEmpty) keyPoints.add(cleaned);
          }
          break;
        case 'keyPoints':
          if (line.startsWith('*') || line.startsWith('-') || line.startsWith('•')) {
            final cleaned = line.replaceFirst(RegExp(r'^[\*\-•]\s*'), '').replaceAll('**', '');
            if (cleaned.isNotEmpty) keyPoints.add(cleaned);
          }
          break;
        case 'definitions':
          if (line.contains(':')) {
            final parts = line.replaceFirst(RegExp(r'^[\*\-•\d\.]\s*'), '').split(':');
            if (parts.length >= 2) {
              final term = parts[0].replaceAll('**', '').trim();
              final meaning = parts.sublist(1).join(':').trim();
              if (term.isNotEmpty && meaning.isNotEmpty) {
                definitions.add(Definition(term: term, meaning: meaning));
              }
            }
          }
          break;
      }
    }

    overview = overviewBuffer.toString().trim();
    if (overview.isEmpty) {
      overview = 'Summary generated successfully. See key points below.';
    }

    return Summary(
      noteTitle: '',
      overview: overview,
      keyPoints: keyPoints.isEmpty ? ['See the full summary above.'] : keyPoints,
      definitions: definitions,
    );
  }
}

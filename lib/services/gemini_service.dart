import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ai_study_companion/models/quiz.dart';

/// Custom exception for AI service errors.
class AIException implements Exception {
  final String message;
  const AIException(this.message);

  @override
  String toString() => message;
}

/// Service for Gemini AI integration — generates summaries and quizzes
/// from extracted PDF text.
class GeminiService {
  late final GenerativeModel _model;
  bool _initialized = false;

  /// Initializes the Gemini model with the API key from .env.
  void initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      throw const AIException(
        'Gemini API key not configured. Please add your key to the .env file.',
      );
    }

    _model = GenerativeModel(
      model: 'gemini-3.1-flash-lite',
      apiKey: apiKey,
    );
    _initialized = true;
  }

  /// Generates a Markdown summary from extracted PDF text.
  ///
  /// Returns a formatted Markdown string with overview, key concepts,
  /// and definitions.
  Future<String> generateSummary(String extractedText) async {
    _ensureInitialized();

    if (extractedText.trim().isEmpty) {
      throw const AIException('No text could be extracted from this PDF.');
    }

    try {
      final prompt = '''
You are an expert academic tutor. Summarize the following text.
Provide a brief overview paragraph, followed by a bulleted list of 5-7 key concepts,
and end with 3 crucial definitions.
Format the entire response in clean Markdown.

Text to summarize:
$extractedText
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        throw const AIException('Received empty response from AI.');
      }

      return text.trim();
    } on AIException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('not found for API') || msg.contains('API key') || msg.contains('invalid')) {
        throw const AIException(
          'Your Gemini API key appears to be invalid, restricted, or unauthorized. '
          'Please ensure you are using a standard Gemini API key from Google AI Studio (typically starting with "AIzaSy") inside your .env file.'
        );
      }
      throw AIException(
        'Failed to generate summary. Please check your internet connection. Error: $e',
      );
    }
  }

  /// Generates a quiz from extracted PDF text.
  ///
  /// Returns a list of [QuizQuestion] objects parsed from the AI's JSON response.
  Future<List<QuizQuestion>> generateQuiz(String extractedText) async {
    _ensureInitialized();

    if (extractedText.trim().isEmpty) {
      throw const AIException('No text could be extracted from this PDF.');
    }

    try {
      final prompt = '''
Generate a 3-question multiple-choice quiz based on the provided text.
You MUST return the output strictly as a JSON array of objects.
Each object must have a "question" (string), "options" (array of 4 strings),
and "correctAnswerIndex" (integer 0-3).
Do not include markdown formatting or backticks in the response.

Text:
$extractedText
''';

      final response = await _model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw const AIException('Received empty response from AI.');
      }

      // Parse JSON response
      final List<dynamic> jsonList = jsonDecode(text.trim()) as List<dynamic>;

      return jsonList.map((item) {
        final map = item as Map<String, dynamic>;
        return QuizQuestion(
          question: map['question'] as String,
          options: List<String>.from(map['options'] as List<dynamic>),
          correctIndex: map['correctAnswerIndex'] as int,
        );
      }).toList();
    } on AIException {
      rethrow;
    } on FormatException {
      throw const AIException(
        'Failed to parse quiz response. The AI returned an unexpected format.',
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('not found for API') || msg.contains('API key') || msg.contains('invalid')) {
        throw const AIException(
          'Your Gemini API key appears to be invalid, restricted, or unauthorized. '
          'Please ensure you are using a standard Gemini API key from Google AI Studio (typically starting with "AIzaSy") inside your .env file.'
        );
      }
      throw AIException(
        'Failed to generate quiz. Please check your internet connection. Error: $e',
      );
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ai_study_companion/models/quiz.dart';

/// Custom exception for AI service errors.
class AIException implements Exception {
  final String message;
  const AIException(this.message);

  @override
  String toString() => message;
}

/// Service for Gemini AI integration — generates summaries and quizzes.
///
/// Uses direct HTTP calls to the Gemini REST API so we can try multiple
/// authentication methods (API-key query-param AND Bearer token) and
/// multiple model names automatically.
class GeminiService {
  String? _apiKey;
  bool _initialized = false;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Models to try, in order.
  static const _models = [
    'gemini-3.1-flash-lite',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  // ── Initialization ────────────────────────────────────────────────────────

  void initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      throw const AIException(
        'Gemini API key not configured. Please add your key to the .env file.',
      );
    }
    _apiKey = apiKey;
    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) initialize();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Generates a Markdown summary from extracted text.
  Future<String> generateSummary(String extractedText) async {
    _ensureInitialized();
    if (extractedText.trim().isEmpty) {
      throw const AIException('No text could be extracted from this document.');
    }

    final prompt = '''
You are an expert academic tutor. Summarize the following text.
Provide a brief overview paragraph, followed by a bulleted list of 5-7 key concepts,
and end with 3 crucial definitions.
Format the entire response in clean Markdown.

Text to summarize:
$extractedText
''';

    final text = await _callGemini(prompt);
    if (text.trim().isEmpty) {
      throw const AIException('Received empty response from AI.');
    }
    return text.trim();
  }

  /// Generates a conceptual quiz from extracted text.
  Future<List<QuizQuestion>> generateQuiz(
    String extractedText, {
    int count = 10,
  }) async {
    _ensureInitialized();
    if (extractedText.trim().isEmpty) {
      throw const AIException('No text could be extracted from this document.');
    }

    final prompt = '''
You are an expert professor and assessment designer.
Generate a $count-question multiple-choice quiz testing deep conceptual understanding of the core topics, principles, and concepts covered in the provided text.

CRITICAL REQUIREMENTS:
1. Create EXACTLY $count distinct multiple-choice questions.
2. Do NOT simply copy exact sentence fragments or verbatim phrasing from the text. Instead, construct original, concept-focused questions that test understanding, application of principles, key terminology, and logical reasoning related to the topic.
3. Each question must have 4 distinct options with exactly one correct answer.
4. Return ONLY a JSON array of objects without markdown formatting or code fences.
5. Each object MUST have:
   "question": string (the question text),
   "options": array of 4 strings (the multiple choice choices),
   "correctAnswerIndex": integer 0-3 (0-indexed position of the correct choice)

Text content:
$extractedText
''';

    final text = await _callGemini(prompt, responseMimeType: 'application/json');

    try {
      final List<dynamic> jsonList =
          jsonDecode(text.trim()) as List<dynamic>;
      return jsonList.map((item) {
        final map = item as Map<String, dynamic>;
        return QuizQuestion(
          question: map['question'] as String,
          options: List<String>.from(map['options'] as List<dynamic>),
          correctIndex: map['correctAnswerIndex'] as int,
        );
      }).toList();
    } on FormatException {
      throw const AIException(
        'Failed to parse quiz response. The AI returned an unexpected format.',
      );
    }
  }

  // ── Core HTTP layer ───────────────────────────────────────────────────────

  /// Tries every combination of (model × auth-method) until one succeeds.
  Future<String> _callGemini(
    String prompt, {
    String? responseMimeType,
  }) async {
    final errors = <String>[];

    for (final model in _models) {
      // ── Attempt 1: API key as query parameter ──
      try {
        final result = await _post(
          '$_baseUrl/$model:generateContent?key=$_apiKey',
          _buildBody(prompt, responseMimeType),
        );
        if (result != null && result.trim().isNotEmpty) return result;
      } catch (e) {
        errors.add('[$model ?key] $e');
        debugPrint('Gemini [$model ?key] failed: $e');
      }

      // ── Attempt 2: API key as Bearer token ──
      try {
        final result = await _post(
          '$_baseUrl/$model:generateContent',
          _buildBody(prompt, responseMimeType),
          bearerToken: _apiKey,
        );
        if (result != null && result.trim().isNotEmpty) return result;
      } catch (e) {
        errors.add('[$model Bearer] $e');
        debugPrint('Gemini [$model Bearer] failed: $e');
      }
    }

    throw AIException(
      'All Gemini API attempts failed. Please check your API key and internet connection.\n${errors.join('\n')}',
    );
  }

  Map<String, dynamic> _buildBody(String prompt, String? responseMimeType) {
    return {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      if (responseMimeType != null)
        'generationConfig': {'responseMimeType': responseMimeType},
    };
  }

  /// Makes a POST request and returns the generated text, or throws.
  Future<String?> _post(
    String url,
    Map<String, dynamic> body, {
    String? bearerToken,
  }) async {
    final client = HttpClient();
    try {
      final request = await client
          .postUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 60));
      request.headers.set('Content-Type', 'application/json');
      if (bearerToken != null) {
        request.headers.set('Authorization', 'Bearer $bearerToken');
      }
      request.write(jsonEncode(body));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final candidates = json['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] as String?;
          }
        }
        return null;
      }

      // Non-200 → throw so we can try the next method
      final errorJson = jsonDecode(responseBody) as Map<String, dynamic>?;
      final errorMsg =
          errorJson?['error']?['message'] ?? 'HTTP ${response.statusCode}';
      throw Exception(errorMsg);
    } finally {
      client.close();
    }
  }
}

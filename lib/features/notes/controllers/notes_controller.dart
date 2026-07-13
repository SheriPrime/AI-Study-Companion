import 'package:flutter/foundation.dart';
import 'package:ai_study_companion/models/note.dart';
import 'package:ai_study_companion/services/mock_database_service.dart';

/// Controller for the Notes screen.
///
/// Manages note loading, subject-based filtering, and note uploads.
/// Works with [MockDatabaseService] to simulate backend operations.
class NotesController extends ChangeNotifier {
  final MockDatabaseService _databaseService;

  NotesController(this._databaseService);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  List<Note> _notes = [];
  List<Note> get notes => List.unmodifiable(_notes);

  String? _selectedSubject;
  String? get selectedSubject => _selectedSubject;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // Derived getters
  // ---------------------------------------------------------------------------

  /// Returns notes filtered by [selectedSubject], or all notes when null.
  List<Note> get filteredNotes {
    if (_selectedSubject == null) return notes;
    return _notes.where((n) => n.subject == _selectedSubject).toList();
  }

  /// Returns a deduplicated, sorted list of subjects across all notes.
  List<String> get subjects {
    final set = _notes.map((n) => n.subject).toSet();
    return set.toList()..sort();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Loads notes from the database service.
  Future<void> loadNotes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notes = List.from(await _databaseService.getNotes());
    } catch (e) {
      _errorMessage = 'Failed to load notes. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Uploads a new note and appends it to the list on success.
  Future<bool> uploadNote(String title, String subject, String fileName) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final note = await _databaseService.uploadNote(title, subject, fileName);
      _notes.insert(0, note);
      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Upload failed. Please try again.';
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sets the active subject filter. Pass `null` to show all notes.
  void filterBySubject(String? subject) {
    _selectedSubject = subject;
    notifyListeners();
  }
}

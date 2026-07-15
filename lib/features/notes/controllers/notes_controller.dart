import 'package:flutter/foundation.dart';
import 'package:ai_study_companion/models/note.dart';
import 'package:ai_study_companion/core/db/database_helper.dart';
import 'package:ai_study_companion/services/local_file_service.dart';

/// Controller for the Notes screen.
///
/// Manages note loading, subject-based filtering, and note uploads.
/// Works with [DatabaseHelper] for SQLite persistence and
/// [LocalFileService] for PDF file picking/copying.
class NotesController extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final LocalFileService _fileService;

  NotesController(this._dbHelper, this._fileService);

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

  /// Loads notes from the SQLite database.
  Future<void> loadNotes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _dbHelper.fetchNotes();
      _notes = rows.map((row) => Note.fromMap(row)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load notes. Please try again.';
      debugPrint('NotesController.loadNotes error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Opens the file picker, copies the PDF to app storage, and saves the
  /// note metadata to SQLite.
  Future<bool> uploadNote(String title, String subject) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Pick file
      final pickedFile = await _fileService.pickPDFFile();
      if (pickedFile == null) {
        // User cancelled
        _isUploading = false;
        notifyListeners();
        return false;
      }

      // 2. Copy to app directory
      final localPath = await _fileService.copyToAppDirectory(pickedFile);

      // 3. Save to SQLite
      final note = Note(
        title: title,
        subject: subject,
        localFilePath: localPath,
        dateAdded: DateTime.now(),
      );

      final id = await _dbHelper.insertNote(note.toMap());

      // 4. Add to local list with the auto-generated id
      final savedNote = Note(
        id: id,
        title: note.title,
        subject: note.subject,
        localFilePath: note.localFilePath,
        dateAdded: note.dateAdded,
      );
      _notes.insert(0, savedNote);

      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Upload failed. Please try again.';
      debugPrint('NotesController.uploadNote error: $e');
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

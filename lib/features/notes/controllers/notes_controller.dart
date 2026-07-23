import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_study_companion/models/note.dart';
import 'package:ai_study_companion/core/db/database_helper.dart';
import 'package:ai_study_companion/services/local_file_service.dart';
import 'package:ai_study_companion/services/firestore_service.dart';

/// Controller for the Notes screen.
///
/// Manages note loading, custom courses, subject-based filtering, and note uploads.
class NotesController extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final LocalFileService _fileService;
  final FirestoreService _firestoreService;

  NotesController(this._dbHelper, this._fileService, this._firestoreService);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  List<Note> _notes = [];
  List<Note> get notes => List.unmodifiable(_notes);

  List<String> _courses = [];
  List<String> get courses => List.unmodifiable(_courses);

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

  /// Returns a deduplicated, sorted list of subjects across notes and custom courses.
  List<String> get subjects {
    final set = _notes.map((n) => n.subject).toSet();
    set.addAll(_courses);
    return set.toList()..sort();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Loads notes from Firestore (syncing across devices) and local SQLite fallback.
  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('local_userUid');
    if (uid == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch local SQLite notes
      final localRows = await _dbHelper.fetchNotes();
      final localNotes = localRows.map((row) => Note.fromMap(row)).toList();

      // 2. Fetch remote Firestore notes
      final remoteRows = await _firestoreService.fetchNotes(uid);
      final remoteNotes = remoteRows.map((row) => Note.fromMap(row)).toList();

      // 3. Merge notes (preferring local path if present)
      final Map<String, Note> noteMap = {};
      for (final n in remoteNotes) {
        noteMap[n.title] = n;
      }
      for (final n in localNotes) {
        noteMap[n.title] = n;
      }

      _notes = noteMap.values.toList()
        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

      _courses = await _firestoreService.fetchCourses(uid);
    } catch (e) {
      _errorMessage = 'Failed to load notes. Please try again.';
      debugPrint('NotesController.loadNotes error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a custom course for the user to Firestore and updates local state.
  Future<void> addCourse(String courseName) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('local_userUid');
    if (uid == null) return;

    try {
      await _firestoreService.addCourse(uid, courseName);
      if (!_courses.contains(courseName)) {
        _courses.add(courseName);
        _courses.sort();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to add course.';
      notifyListeners();
    }
  }

  /// Copies the file to app storage and saves the note metadata to SQLite and Firestore.
  Future<bool> uploadNote(String title, String subject, File file) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('local_userUid');

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Copy to app directory
      final localPath = await _fileService.copyToAppDirectory(file);

      // 2. Extract text if possible for Cloud sync
      String? textContent;
      try {
        if (file.path.endsWith('.txt')) {
          textContent = await file.readAsString();
        }
      } catch (_) {}

      // 3. Save to SQLite
      final note = Note(
        title: title,
        subject: subject,
        localFilePath: localPath,
        dateAdded: DateTime.now(),
      );

      final id = await _dbHelper.insertNote(note.toMap());

      // 4. Save to Firestore if logged in
      if (uid != null) {
        await _firestoreService.uploadNote(
          uid: uid,
          title: title,
          subject: subject,
          localFilePath: localPath,
          fileContent: textContent,
        );
      }

      // 5. Add to local list with the auto-generated id
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

  /// Deletes a note from SQLite database and Cloud Firestore.
  Future<bool> deleteNote(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('local_userUid');

    try {
      final index = _notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        final note = _notes[index];
        // Delete SQLite record
        await _dbHelper.deleteNote(id);
        
        // Delete Firestore record
        if (uid != null) {
          await _firestoreService.deleteNote(uid, note.title);
        }

        // Try deleting local file
        try {
          final file = File(note.localFilePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Failed to delete physical file: $e');
        }

        _notes.removeAt(index);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete note.';
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

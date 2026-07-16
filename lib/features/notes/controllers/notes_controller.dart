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

  /// Loads notes from local SQLite database and custom courses from Firestore.
  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('local_userUid');
    if (uid == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _dbHelper.fetchNotes();
      _notes = rows.map((row) => Note.fromMap(row)).toList();
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

  /// Copies the file to app storage and saves the note metadata to SQLite.
  Future<bool> uploadNote(String title, String subject, File file) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Copy to app directory
      final localPath = await _fileService.copyToAppDirectory(file);

      // 2. Save to SQLite
      final note = Note(
        title: title,
        subject: subject,
        localFilePath: localPath,
        dateAdded: DateTime.now(),
      );

      final id = await _dbHelper.insertNote(note.toMap());

      // 3. Add to local list with the auto-generated id
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

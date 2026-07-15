import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Thread-safe Singleton helper for the local SQLite database.
///
/// Manages table creation and provides CRUD operations for
/// notes, tasks, and study statistics.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  /// Returns the singleton database instance, creating it on first access.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_study_companion.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        local_file_path TEXT NOT NULL,
        date_uploaded TEXT NOT NULL
      )
    ''');

    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        time TEXT,
        status TEXT NOT NULL DEFAULT 'Pending'
      )
    ''');

    // Study stats table
    await db.execute('''
      CREATE TABLE study_stats (
        date TEXT PRIMARY KEY,
        daily_goal_progress REAL NOT NULL DEFAULT 0.0,
        quizzes_taken INTEGER NOT NULL DEFAULT 0,
        streak INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ─── Notes CRUD ──────────────────────────────────────────────────────────

  /// Inserts a note and returns the auto-generated id.
  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    return db.insert('notes', note);
  }

  /// Fetches all notes, ordered by date descending.
  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final db = await database;
    return db.query('notes', orderBy: 'date_uploaded DESC');
  }

  /// Deletes a note by id.
  Future<int> deleteNote(int id) async {
    final db = await database;
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Tasks CRUD ─────────────────────────────────────────────────────────

  /// Inserts a task and returns the auto-generated id.
  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return db.insert('tasks', task);
  }

  /// Fetches all tasks, ordered by date ascending.
  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final db = await database;
    return db.query('tasks', orderBy: 'date ASC');
  }

  /// Updates a task's status by id.
  Future<int> updateTaskStatus(int id, String status) async {
    final db = await database;
    return db.update(
      'tasks',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a task by id.
  Future<int> deleteTask(int id) async {
    final db = await database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Study Stats CRUD ───────────────────────────────────────────────────

  /// Inserts or replaces stats for a given date.
  Future<int> upsertStats(Map<String, dynamic> stats) async {
    final db = await database;
    return db.insert(
      'study_stats',
      stats,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetches stats for a specific date.
  Future<Map<String, dynamic>?> getStatsForDate(String date) async {
    final db = await database;
    final result = await db.query(
      'study_stats',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Fetches stats for the last N days.
  Future<List<Map<String, dynamic>>> getRecentStats(int days) async {
    final db = await database;
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).toIso8601String().substring(0, 10);
    return db.query(
      'study_stats',
      where: 'date >= ?',
      whereArgs: [cutoff],
      orderBy: 'date ASC',
    );
  }

  /// Returns the total number of notes.
  Future<int> getNotesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns notes grouped by subject with counts.
  Future<List<Map<String, dynamic>>> getNotesCountBySubject() async {
    final db = await database;
    return db.rawQuery(
      'SELECT subject, COUNT(*) as count FROM notes GROUP BY subject ORDER BY count DESC',
    );
  }
}

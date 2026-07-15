/// Represents an uploaded study note / PDF.
class Note {
  final int? id;
  final String title;
  final String subject;
  final String localFilePath;
  final DateTime dateAdded;

  const Note({
    this.id,
    required this.title,
    required this.subject,
    required this.localFilePath,
    required this.dateAdded,
  });

  /// Creates a [Note] from a SQLite row map.
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      subject: map['subject'] as String,
      localFilePath: map['local_file_path'] as String,
      dateAdded: DateTime.parse(map['date_uploaded'] as String),
    );
  }

  /// Converts this [Note] to a map for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'subject': subject,
      'local_file_path': localFilePath,
      'date_uploaded': dateAdded.toIso8601String(),
    };
  }

  /// Convenience getter for backward compatibility with UI displaying file name.
  String get fileName => localFilePath.split('/').last;
}

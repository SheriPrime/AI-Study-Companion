/// Represents an uploaded study note / PDF.
class Note {
  final String id;
  final String title;
  final String subject;
  final String fileName;
  final DateTime dateAdded;
  final int pageCount;

  const Note({
    required this.id,
    required this.title,
    required this.subject,
    required this.fileName,
    required this.dateAdded,
    required this.pageCount,
  });
}

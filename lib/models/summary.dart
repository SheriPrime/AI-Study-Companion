/// AI-generated summary of a study note.
class Summary {
  final String noteTitle;
  final String overview;
  final List<String> keyPoints;
  final List<Definition> definitions;

  const Summary({
    required this.noteTitle,
    required this.overview,
    required this.keyPoints,
    required this.definitions,
  });
}

/// A key term and its definition extracted from a note.
class Definition {
  final String term;
  final String meaning;

  const Definition({required this.term, required this.meaning});
}

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service for local file operations: picking, copying to app directory,
/// and extracting text from PDF files.
class LocalFileService {
  /// Opens a file picker restricted to PDF files.
  /// Returns the picked [File] or null if cancelled.
  Future<File?> pickPDFFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Copies the given [sourceFile] into the app's documents directory
  /// under a `notes/` subdirectory. Returns the new local path.
  Future<String> copyToAppDirectory(File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final notesDir = Directory(p.join(appDir.path, 'notes'));

    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }

    // Use timestamp to avoid name collisions
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalName = p.basename(sourceFile.path);
    final newFileName = '${timestamp}_$originalName';
    final newPath = p.join(notesDir.path, newFileName);

    await sourceFile.copy(newPath);
    return newPath;
  }

  /// Extracts all text content from a PDF file at the given [localFilePath].
  ///
  /// Uses Syncfusion PDF library for reliable text extraction.
  /// Returns the full extracted text as a single string.
  Future<String> extractTextFromPDF(String localFilePath) async {
    try {
      final file = File(localFilePath);
      final bytes = await file.readAsBytes();

      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);

      final StringBuffer fullText = StringBuffer();
      for (int i = 0; i < document.pages.count; i++) {
        final pageText = extractor.extractText(startPageIndex: i);
        fullText.writeln(pageText);
      }

      document.dispose();
      return fullText.toString().trim();
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }
}

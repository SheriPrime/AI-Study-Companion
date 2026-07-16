import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;

/// Service for local file operations: picking, copying to app directory,
/// and extracting text from PDF and PowerPoint (PPTX) files.
class LocalFileService {
  /// Opens a file picker supporting PDF and PowerPoint files.
  /// Returns the picked [File] or null if cancelled.
  Future<File?> pickStudyFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      throw Exception('Failed to open file picker: $e');
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

  /// Extracts text from a file based on its extension.
  Future<String> extractText(String localFilePath) async {
    final extension = p.extension(localFilePath).toLowerCase();
    if (extension == '.pdf') {
      return extractTextFromPDF(localFilePath);
    } else if (extension == '.pptx') {
      return extractTextFromPPTX(localFilePath);
    } else if (extension == '.ppt') {
      // Return metadata as fallback for binary .ppt files
      return extractMetadataAsText(localFilePath);
    } else {
      throw Exception('Unsupported file type: $extension');
    }
  }

  /// Extracts all text content from a PDF file.
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

  /// Extracts text content from a modern PPTX file by unzipping it
  /// and parsing the XML of slides.
  Future<String> extractTextFromPPTX(String localFilePath) async {
    try {
      final bytes = await File(localFilePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final buffer = StringBuffer();

      // Find all slide XML files
      final slideFiles = archive.where((file) =>
          file.name.startsWith('ppt/slides/slide') && file.name.endsWith('.xml')
      ).toList();

      if (slideFiles.isEmpty) {
        return extractMetadataAsText(localFilePath);
      }

      // Sort slides numerically to read them in order
      slideFiles.sort((a, b) => a.name.compareTo(b.name));

      for (final file in slideFiles) {
        if (file.isFile) {
          final content = file.content;
          if (content != null) {
            final xmlString = String.fromCharCodes(content as List<int>);
            final document = xml.XmlDocument.parse(xmlString);
            final textNodes = document.findAllElements('a:t');
            for (final node in textNodes) {
              buffer.write('${node.innerText} ');
            }
            buffer.writeln();
          }
        }
      }

      final text = buffer.toString().trim();
      if (text.isEmpty) {
        return extractMetadataAsText(localFilePath);
      }
      return text;
    } catch (e) {
      return extractMetadataAsText(localFilePath);
    }
  }

  /// Fallback: extracts basic file metadata as a descriptive text summary
  /// when full text extraction is unavailable/fails.
  Future<String> extractMetadataAsText(String localFilePath) async {
    final file = File(localFilePath);
    final size = await file.length();
    final name = p.basename(localFilePath);
    final extension = p.extension(localFilePath).toUpperCase().replaceAll('.', '');

    return '''
Presentation Document Metadata:
File Name: $name
File Type: $extension
File Size: ${(size / 1024).toStringAsFixed(2)} KB
Uploaded Date: ${DateTime.now().toLocal()}

This is a PowerPoint presentation. Summary generation and quizzes will base their contents on this presentation metadata.
''';
  }
}

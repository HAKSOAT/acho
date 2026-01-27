import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_app/src/rust/api/simple.dart';
import 'package:flutter_tantivy/flutter_tantivy.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_pdf/pdf.dart';

// import 'package:path_provider/path_provider.dart'; (Optional if you need specific paths)

class PdfScanner {
  Future<List<FileSystemEntity>> getAllPdfs() async {
    List<FileSystemEntity> pdfs = [];

    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    Directory rootDir = Directory('/storage/emulated/0/');

    try {
      await _searchForPdfs(rootDir, pdfs);
    } catch (e) {
      print("Error scanning: $e");
    }

    return pdfs;
  }

  // Recursive function to walk through folders
  Future<void> _searchForPdfs(
      Directory dir, List<FileSystemEntity> pdfs) async {
    try {
      List<FileSystemEntity> entities =
          dir.listSync(recursive: false, followLinks: false);

      for (FileSystemEntity entity in entities) {
        // Skip hidden folders (start with .) and the Android data folder (restricted)
        if (entity.path.split('/').last.startsWith('.')) continue;
        if (entity.path.contains('/Android/obb'))
          continue; // Avoid Access Denied errors
        if (entity.path.contains('/Android/data'))
          continue; // Avoid Access Denied errors

        if (entity is File) {
          if (entity.path.toLowerCase().endsWith(".pdf")) {
            pdfs.add(entity);
            print("Found PDF: ${entity.path}");
          }
        } else if (entity is Directory) {
          await _searchForPdfs(entity, pdfs);
        }
      }
    } catch (e) {}
  }

  Future<String> openFile(FileSystemEntity file) async {
    final buffer = StringBuffer();
    final stream = File(file.path).openRead().transform(utf8.decoder);

    try {
      await for (final chunk in stream) {
        buffer.write(chunk);
      }
    } catch (e) {
      print("Error reading file: $e");
    }
    return buffer.toString();
  }

  void indexPdfFiles() async {
    ///index by chunks
    List<FileSystemEntity> allPdfs = await getAllPdfs();
    int count = 1;
    for (FileSystemEntity i in allPdfs) {
      final PdfDocument document =
          PdfDocument(inputBytes: File(i.path).readAsBytesSync());
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      final doc = Document(id: i.toString(), text: text);
      count += 1;
      await addDocument(doc: doc);
    }
  }
}

Future<List<SearchResult>> findMatch(String query) async {
  print("searching");
  final results = await searchDocuments(
    query: query,
    topK: BigInt.from(10),
  );
  List<Document> documents = [];
  print("found");
  print(results);

  //
  // for (final result in results) {
  //   print('Score: ${result.score}');
  //   print('ID: ${result.doc.id}');
  //   print('Text: ${result.doc.text}');

  //   Document? doc = getDocumentById(id: result.doc.id);
  //   if (doc != null) {
  //     documents.add(doc);
  //   }
  // }
  return results;
}

///delete document when a document is deleted

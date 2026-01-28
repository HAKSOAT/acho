import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_app/src/rust/api/simple.dart';
import 'package:mobile_app/src/rust/api/acho.dart';
import 'package:path_provider/path_provider.dart';
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
    for (FileSystemEntity i in allPdfs) {
      final PdfDocument document =
          PdfDocument(inputBytes: File(i.path).readAsBytesSync());
      String fileName = i.path.split("/").last;
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      for (int j = 0; j < document.pages.count; j++) {
        String pageText = extractor.extractText(startPageIndex: j);
        final doc = Document(
            id: "${fileName}-${j.toString()}",
            text: pageText.replaceAll(j.toString(), " "));
        await addDocument(doc: doc);
      }
      document.dispose();
    }
  }
}

Future<List<SearchResult>> findMatch(String query) async {
  await RustLib.init();
  final results = await searchDocuments(
    query: query,
    topK: BigInt.from(10),
  );
  print(results);
  return results;
}
// Future<List<Map<String, String>>>
// Future<List<String>> semanticSearch(String query) async {
//   await RustLib.init();
//   final results = await similarity(
//     query: [query],
//     texts: ["Today is a good day", "What is going on?"]
//   );
//   return ["Semantic Search Button pressed"];
// }

Future<void> saveSearchHistory(String text) async {
  final query = text.trim();
  if (query.isEmpty) return;

  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/search_history.txt');

  // 1. Read existing lines into a Set to ensure uniqueness
  Set<String> history = {};
  if (await file.exists()) {
    final lines = await file.readAsLines();
    history = lines.toSet();
  }

  history.remove(query);
  history.add(query);

  await file.writeAsString(history.join('\n') + '\n');
}

Future<List<String>> getSearchHistory() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/search_history.txt');

    if (await file.exists()) {
      String contents = await file.readAsString();
      return contents.trim().split('\n').reversed.toList();
    }
  } catch (e) {
    print("Error reading history: $e");
  }
  return [];
}

///delete document when a document is deleted

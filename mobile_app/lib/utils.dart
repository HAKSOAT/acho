import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_app/src/rust/api/simple.dart';

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

  void openFiles(FileSystemEntity file) async {
    final stream = File(file.path).openRead();
    await for (final data in stream) {
      print(data);
    }
  }

  void openFilesRs() async {}

  void indexPdfFiles() async {}
}

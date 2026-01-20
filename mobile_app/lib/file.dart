import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:gap/gap.dart';
import 'package:mobile_app/utils.dart';

class FileApp extends StatelessWidget {
  late List<FileSystemEntity> files = [];
  FileApp({super.key, required this.files});

  @override
  Widget build(BuildContext context) {

     //TODO:switch to class, so we can access more attributes outside of title


    return SizedBox.shrink(
        child: Column(
      children: [
        const ListTile(
            leading: Text(
          "files",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        )),
        Column(
            children: List.generate(files.length, (int index) {
              String fileName = files[index].path.split("/").last;
              String fileType = files[index].path.split("/").last.split(".").last;

              Map<String, Icon> fileIcon = {"pdf": Icon(Icons.picture_as_pdf)};

          return ListTile(
                leading: fileIcon[fileType] ?? Icon(Icons.book),
                trailing: Icon(Icons.chevron_right),
                //TODO: style to make borders visible
                onTap: () {
                  PdfScanner().openFilesRs();
                  //TODO: Handle click, popular search bar with text controller
                },
                title:
                    Text(fileName), // Display results from search
              );
        })),
      ],
    ));
  }
}

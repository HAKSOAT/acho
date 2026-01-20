import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:gap/gap.dart';
import 'package:mobile_app/utils.dart';

class FolderApp extends StatelessWidget {
  late List<FileSystemEntity> folders = [];
  FolderApp({super.key, required this.folders});

  @override
  Widget build(BuildContext context) {

     //TODO:switch to class, so we can access more attributes outside of title


    return SizedBox.shrink(
        child: Column(
      children: [
        const ListTile(
            leading: Text(
          "Folders",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        )),
        Column(
            children: List.generate(folders.length, (int index) {
              String fileName = folders[index].path.split("/").last;
              String fileType = folders[index].path.split("/").last.split(".").last;

              Map<String, Icon> fileIcon = {"pdf": Icon(Icons.picture_as_pdf)};

          return ListTile(
                leading: fileIcon[fileType] ?? Icon(Icons.book),
                //TODO: style to make borders visible
                onTap: () {
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

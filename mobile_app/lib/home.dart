import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gap/gap.dart';
import 'package:mobile_app/utils.dart';
import 'package:flutter_tantivy/flutter_tantivy.dart';

class HomeApp extends StatefulWidget {
  late List<FileSystemEntity> files = [];
  HomeApp({super.key, required this.files});

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> {
  List<SearchResult> matchedDocuments = [];


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;

    //TODO: cap at 5
    late List<String> searchedItems = ['A', 'B', 'C'];
    //TODO:switch to class, so we can access more attributes outside of title

    return SizedBox.shrink(
        child: Column(
      children: [
        SizedBox(
          height: 70,
          width: width - 40,
          child: SearchBar(
            leading: const Icon(Icons.search),
            hintText: "Search...",

            shape: WidgetStateProperty.all(
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(3)), // This makes the corners square
              ),
            ),

            backgroundColor: WidgetStateProperty.all(Colors.grey[200]),
            elevation: WidgetStateProperty.all(0), // Flat style

            onChanged: (text) {
              //TODO: Handle search logic here
              //spawn process into a new isolate to prevent u.i jank
            },
            onSubmitted: (text) async {
              print("start searching");
              final List<SearchResult> docs = await compute(findMatch, text);
              //TODO: Handle enter key press,
              //TODO: similar to above depending on latency we may just use this

              if (mounted) {
              setState(() {
                matchedDocuments = docs;
              });
              print(matchedDocuments);
            }},
          ),
        ),
        const ListTile(
            leading: Text(
          "Recent Searches",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        )),
        Row(
            children: List.generate(searchedItems.length, (int index) {
          return SizedBox(
              width: 70,
              child: TextButton(
                //TODO: style to make borders visible
                onPressed: () {
                  //TODO: Handle click, popular search bar with text controller
                },
                child:
                    Text(searchedItems[index]), // Display results from search
              ));
        })),
        matchedDocuments.length > 1
            ? const ListTile(
                leading: Text(
                "Matching Documents",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ))
            : SizedBox.shrink(
            child: Column(
              children: [
                const ListTile(
                    leading: Text(
                      "files",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    )),
                Column(
                    children: List.generate(widget.files.length, (int index) {
                      String fileName = widget.files[index].path.split("/").last;
                      String fileType =
                          widget.files[index].path.split("/").last.split(".").last;

                      Map<String, Icon> fileIcon = {"pdf": Icon(Icons.picture_as_pdf)};

                      return ListTile(
                        leading: fileIcon[fileType] ?? Icon(Icons.book),
                        trailing: Icon(Icons.chevron_right),
                        //TODO: style to make borders visible
                        onTap: () {
                          PdfScanner().openFile(widget.files[index]);
                          //TODO: Handle click, popular search bar with text controller
                        },
                        title: Text(fileName), // Display results from search
                      );
                    })),
              ],
            )),
        Column(
            children: List.generate(matchedDocuments.length, (int index) {
          return ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            onTap: () {
              // Handle click
              //Open to segment of document
            },
            trailing: const Icon(Icons.chevron_right),
            title: Text(matchedDocuments[index]
                .doc
                .text.substring(0,50)), // Display results from search
          );
        })),

      ],
    ));
  }
}

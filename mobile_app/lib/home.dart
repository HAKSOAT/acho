import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gap/gap.dart';
import 'package:mobile_app/utils.dart';
import 'package:flutter_tantivy/flutter_tantivy.dart';

class HomeApp extends StatefulWidget {
  List<FileSystemEntity> files = [];
  HomeApp({super.key, required this.files});

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> {
  List<SearchResult> matchedDocuments = [];
  List<String> searchedItems = [];

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;

    void _showDocumentDetails(SearchResult result) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Document Preview"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Matching Chunk:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const Gap(10),
                Text(
                  result.doc.text, // The full text chunk
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            ElevatedButton(
              onPressed: () {
                ///TODO: Integrate with PDF viewer to jump to specific page
                Navigator.pop(context);
              },
              child: const Text("Open Full PDF"),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink(
        child: Column(children: [
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

          onChanged: (text) {},
          onSubmitted: (text) async {
            // final List<SearchResult> docs = await compute(findMatch, text);
            final List<String> ocs = await semanticSearch(text);

            //TODO: Handle enter key press,
            //TODO: similar to above depending on latency we may just use this
            saveSearchHistory(text);
            List<String> _searchedItems = await getSearchHistory();
            setState(() {
              searchedItems = _searchedItems;
            });
            // setState(() {
            //   matchedDocuments = docs;
            // });


          },
        ),
      ),
      const ListTile(
          leading: Text(
        "Recent Searches",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      )),
      Row(
          children: List.generate(min(searchedItems.length, 3), (int index) {
        return Expanded(
            child: OutlinedButton(
          //TODO: style to make borders visible
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(), // Makes it look like a pill/chip
            side: BorderSide(color: Colors.grey[300]!),
          ),
          onPressed: () async {
            final List<SearchResult> docs =
                await compute(findMatch, searchedItems[index]);

            setState(() {
              matchedDocuments = docs;
            });
          },
          child: Text(searchedItems[index]), // Display results from search
        ));
      })),
      matchedDocuments.length >= 1
          ? const ListTile(
              leading: Text(
              "Matching Documents",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ))
          : Expanded(
              child: Column(
              children: [
                const ListTile(
                    leading: Text(
                  "Files",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                )),
                Column(
                    children: List.generate(widget.files.length, (int index) {
                  String fileName = widget.files[index].path.split("/").last;
                  String fileType =
                      widget.files[index].path.split("/").last.split(".").last;

                  Map<String, Icon> fileIcon = {
                    "pdf": Icon(Icons.picture_as_pdf)
                  };

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
      Expanded(
          child: ListView.builder(
              itemCount: matchedDocuments.length,
              itemBuilder: (context, index) {
                final result = matchedDocuments[index];

                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  onTap: () {
                    _showDocumentDetails(result);
                  },
                  trailing: const Icon(Icons.chevron_right),
                  title: Text(result.doc.text
                      .substring(0, 50)), // Display results from search
                );
              })),
    ]));
  }
}

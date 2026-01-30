import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gap/gap.dart';
import 'package:mobile_app/utils.dart';
import 'package:mobile_app/src/rust/frb_generated.dart';
import 'package:mobile_app/src/rust/api/acho.dart';
import 'package:mobile_app/src/rust/api/tantivy.dart';

class HomeApp extends StatefulWidget {
  List<FileSystemEntity> files = [];
  HomeApp({super.key, required this.files});

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> {
  List<SearchResult> matchedDocuments = [];
  List<String> semanticMatchedDocument = [];
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
            final List<SearchResult> docs = await compute(findMatch, text);
            final List<String> sdocs = await compute(
                semanticSearch,
                SemanticSearch(text, ['Ki lo shele', 'Whats happening', 'The way what ?']));

            print(sdocs);
            saveSearchHistory(text);

            List<String> _searchedItems = await getSearchHistory();
            setState(() {
              searchedItems = _searchedItems;
            });

            setState(() {
              matchedDocuments = docs;
            });

            setState(() {
              semanticMatchedDocument = sdocs;
            });
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
            final List<SearchResult> docs = [];
            await compute(findMatch, searchedItems[index]);

            setState(() {
              matchedDocuments = docs;
            });
          },
          child: Text(searchedItems[index]), // Display results from search
        ));
      })),
      const ListTile(
          leading: Text(
        "Keyword Match",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      )),
      matchedDocuments.length >= 1
          ? Expanded(
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
                  }))
          : SizedBox.shrink(),
      Gap(10),
      const ListTile(
          leading: Text(
        "Semantic Match",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      )),
      semanticMatchedDocument.length >= 1
          ? Expanded(
              child: ListView.builder(
                  itemCount: semanticMatchedDocument.length,
                  itemBuilder: (context, index) {
                    final result = semanticMatchedDocument[index];
                    return ListTile(
                      leading: const Icon(Icons.picture_as_pdf),
                      onTap: () {
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
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue),
                                  ),
                                  const Gap(10),
                                  Text(
                                    result, // The full text chunk
                                    style: const TextStyle(
                                        fontSize: 15, height: 1.5),
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
                      },
                      trailing: const Icon(Icons.chevron_right),
                      title: Text(result.length > 50 ? result.substring(
                          0, 50): result), // Display results from search
                    );
                  }))
          : SizedBox.shrink(),
    ]));
  }
}

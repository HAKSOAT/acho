import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class HomeApp extends StatelessWidget {
  const HomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;

    //TODO: cap at 5
    late List<String> searchedItems = ['A', 'B', 'C'];
    late List<String> recentDocuments = [
      'A',
      'B',
      'C'
    ]; //TODO:switch to class, so we can access more attributes outside of title

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
            onSubmitted: (text) {
              //TODO: Handle enter key press,
              //TODO: similar to above depending on latency we may just use this
            },
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
        const ListTile(
            leading: Text(
          "Recent Documents",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        )),
        Column(
            children: List.generate(recentDocuments.length, (int index) {
          return ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            onTap: () {
              // Handle click
            },
            trailing: const Icon(Icons.chevron_right),
            title: Text(recentDocuments[index]), // Display results from search
          );
        }))
      ],
    ));
  }
}

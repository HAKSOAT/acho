import 'package:flutter/material.dart';

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const SizedBox.shrink(
        child: Column(
      children: [
        ListTile(
          leading: Text(
            "Search Settings",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          // onTap:,
        ),
        ListTile(
          leading: Icon(Icons.folder),
          title: Text("Folder"),
          trailing: Icon(Icons.chevron_right_sharp),
          // onTap:,
        ),
        ListTile(
          leading: Icon(Icons.change_circle_sharp),
          title: Text("Re-index PDFs"),
          trailing: Icon(Icons.chevron_right_sharp),
          // onTap:,
        ),
        Divider(),
        ListTile(
          leading: Text(
            "Display",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Divider(),
        ListTile(
          leading: Text(
            "Storage",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          // onTap:,
        ),
        ListTile(
          leading: Text(
            "Index Size",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          // onTap:,
        ),
        ListTile(
          leading: Icon(Icons.delete_forever_rounded),
          title: Text("Clear search history"),
          trailing: Icon(Icons.chevron_right),
          // onTap:,
        ),
        Divider(),
        ListTile(
          leading: Text(
            "About",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          // onTap:,
        ),
        ListTile(
          leading: Text(
            "Version 1.0.0",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          // onTap:,
        ),
        ListTile(
          leading: Text(
            "Help & Feedback",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          // onTap:,
        )
      ],
    ));
  }
}

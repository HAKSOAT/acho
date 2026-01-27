import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/src/rust/frb_generated.dart';
import 'package:mobile_app/settings.dart';
import 'package:mobile_app/home.dart';
import 'package:mobile_app/file.dart';
import 'package:mobile_app/storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_app/utils.dart';

Future<void> main() async {
  await RustLib.init();
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure plugin services are initialized

  RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  await Log.init();

  var status = await Permission.manageExternalStorage.status;

  if (!status.isGranted) {
    status = await Permission.manageExternalStorage.request();
  }

  status = await Permission.manageExternalStorage.status;
  Log.logger.i("Permission for external storage: $status");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  PageController pageController = PageController();
  List<FileSystemEntity> folders = [];

  int selectIndex = 0;
  void onPageChanged(int index) {
    setState(() {
      selectIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPdfs();
  }

  void _loadPdfs() async {
    PdfScanner scanner = PdfScanner();
    List<FileSystemEntity> files =
        await scanner.getAllPdfs(); // This might block UI if not careful
    setState(() {
      folders = files;
    });
  }

  void onItemTap(int selectedItems) {
    pageController.jumpToPage(selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(title: const Text('Acho')),
          body: PageView(
            children: [HomeApp(), FileApp(files: folders), SettingsApp()],
            controller: pageController,
            onPageChanged: onPageChanged,
          ),
          bottomNavigationBar: BottomNavigationBar(
              onTap: onItemTap,
              selectedItemColor: Colors.brown,
              items: [
                const BottomNavigationBarItem(
                  backgroundColor: Colors.red,
                  label: 'Home',
                  icon: Icon(Icons.home_filled),
                  activeIcon: HomeApp(),
                ),
                BottomNavigationBarItem(
                  backgroundColor: Colors.red,
                  label: 'Files',
                  icon: Icon(Icons.folder),
                  activeIcon: FileApp(
                    files: [],
                  ),
                ),
                const BottomNavigationBarItem(
                  label: 'Settings',
                  icon: Icon(Icons.settings),
                  activeIcon: SettingsApp(),
                )
              ])),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_app/src/rust/frb_generated.dart';
import 'package:mobile_app/settings.dart';
import 'package:mobile_app/home.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  PageController pageController = PageController();

  int selectIndex = 0;
  void onPageChanged(int index) {
    setState(() {
      selectIndex = index;
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
            children: [HomeApp(), SettingsApp()],
            controller: pageController,
            onPageChanged: onPageChanged,
          ),
          bottomNavigationBar: BottomNavigationBar(
              onTap: onItemTap,
              selectedItemColor: Colors.brown,
              items: const [
                BottomNavigationBarItem(
                  backgroundColor: Colors.red,
                  label: 'Home',
                  icon: Icon(Icons.home_filled),
                  activeIcon: HomeApp(),
                ),
                BottomNavigationBarItem(
                  label: 'Settings',
                  icon: Icon(Icons.settings),
                  activeIcon: SettingsApp(),
                )
              ])),
    );
  }
}

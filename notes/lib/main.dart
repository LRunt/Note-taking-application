import 'package:flutter/material.dart';

import 'package:notes/screens/mainScreen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const appTitle = 'Notes';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainScreen()
    );
  }
}
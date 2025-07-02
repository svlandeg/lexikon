import 'package:flutter/material.dart';
import 'screens.dart';

void main() {
  runApp(const LexikonApp());
}

class LexikonApp extends StatelessWidget {
  const LexikonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lexikon',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

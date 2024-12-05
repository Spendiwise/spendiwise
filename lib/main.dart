// main.dart
import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';

void main() {
  runApp(SpendiwiseApp());
}

class SpendiwiseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendiwise',
      theme: ThemeData(
        primarySwatch: Colors.blue),
      home: LandingScreen(),
    );
  }
}

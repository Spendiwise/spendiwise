// main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/landing_screen.dart';
import 'automaticTransaction//category_inference.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Firebase initialization
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSy…",
        authDomain: "spendiwise-48c7f.firebaseapp.com",
        projectId: "spendiwise-48c7f",
        storageBucket: "spendiwise-48c7f.firebasestorage.app",
        messagingSenderId: "810215813772",
        appId: "1:810215813772:web:…",
        measurementId: "G-D20HC5NVXQ",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // 2) Load dynamic category mappings
  await CategoryInference.init();

  // 3) Start app
  runApp(const SpendiwiseApp());
}

class SpendiwiseApp extends StatelessWidget {
  const SpendiwiseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendiwise',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LandingScreen(),
    );
  }
}

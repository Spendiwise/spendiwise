// main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'screens/landing_screen.dart';
import 'automaticTransaction//category_inference.dart';
import 'utils/app_globals.dart';


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
/*
  /// 2) USE FIREBASE EMULATOR (only for local testing)///
  if (kDebugMode) {
    // Connect Firebase Auth to emulator
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

    // Connect Firestore to emulator
    FirebaseFirestore.instance.settings = const Settings(
      host: 'localhost:8080',
      sslEnabled: false,
      persistenceEnabled: false,
    );
  }
*/
  // 3) Load dynamic category mappings
  await CategoryInference.init();

  // 4) Start app
  runApp(const SpendiwiseApp());
}

class SpendiwiseApp extends StatelessWidget {
  const SpendiwiseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Spendiwise',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LandingScreen(),
    );
  }
}

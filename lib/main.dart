// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/landing_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyAiOx7XwDGH0ikxbHTUJBSWwLFBTB5GAsk",
            authDomain: "spendiwise-48c7f.firebaseapp.com",
            projectId: "spendiwise-48c7f",
            storageBucket: "spendiwise-48c7f.firebasestorage.app",
            messagingSenderId: "810215813772",
            appId: "1:810215813772:web:4f569a7a227825565201a9",
            measurementId: "G-D20HC5NVXQ"
        ),
    );
  }
else {
  await Firebase.initializeApp(); // Initialize Firebase
}
runApp(SpendiwiseApp());
}

class SpendiwiseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendiwise',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LandingScreen(),
    );
  }
}

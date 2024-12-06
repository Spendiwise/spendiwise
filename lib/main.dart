// main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tryout/screens/register_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(SpendiwiseApp());
}

class SpendiwiseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendiwise',
      theme: ThemeData(
        primarySwatch: Colors.blue),
      home: StreamBuilder
      (stream: FirebaseAuth.instance.authStateChanges(), 
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(),);
        }
        if (snapshot.data != null)
        {
          return LandingScreen();
        }
        return RegisterScreen();
      }
      )
      
    );
  }
}

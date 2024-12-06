// register_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

@override
// ignore: override_on_non_overriding_member
void dispose() {
  emailController.dispose();
  passwordController.dispose();
  confirmPasswordController.dispose();
}

Future<void> createUserWithEmailandPassword() async {
  try {

final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: emailController.text.trim(), 
    password: passwordController.text.trim(),
    );
    print(userCredential.user);
  } on FirebaseAuthException catch(e) {
    print(e);
  }
  
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await createUserWithEmailandPassword();
                Navigator.pop(context);
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'login_screen.dart';  // Import the login screen
import 'register_screen.dart';  // Import the register screen

class LandingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(  // This will center the content both vertically and horizontally
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,  // Centers vertically
            crossAxisAlignment: CrossAxisAlignment.center,  // Centers horizontally
            children: [
              // Optional: You can add a logo if you have one
              Image.asset(
                'assets/images/logo.png',  // Ensure this path is correct for your project
                 width: 150,
                 height: 150,
              ),
              SizedBox(height: 20), // Space between logo and app name

              // App name
              Text(
                'SpendiWise',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,  // You can change the color here
                ),
              ),
              SizedBox(height: 40),  // Space between app name and buttons

              // Login Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to LoginScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text('Login'),
              ),

              SizedBox(height: 20), // Space between buttons

              // Register Button
              TextButton(
                onPressed: () {
                  // Navigate to RegisterScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Text('Register Here'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

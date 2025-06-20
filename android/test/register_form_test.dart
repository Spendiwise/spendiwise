import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:tryout/lib/screens/login_screen.dart'; // replace with correct path

void main() {
  testWidgets('Login screen loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen()) // replace with your actual login widget
    );

    await tester.pumpAndSettle(); // waits for animations/futures

    expect(find.text('Log In'), findsOneWidget); // double-check your actual widget text!
  });
}
flutter test test/login_screen_test.dart
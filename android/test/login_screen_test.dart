import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:tryout/lib/screens/login_screen.dart'; // Adjust import path

void main() {
  group('LoginScreen Tests', () {
    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('navigates on valid input', (tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'test@mail.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget); // Adjust to your landing page
    });
  });
}

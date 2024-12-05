import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tryout/main.dart';

void main() {
  testWidgets('Login screen loads correctly', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(SpendiwiseApp());

    // Verify that the "Log In" button is present.
    expect(find.text('Log In'), findsOneWidget);

    // Verify that the "Register Here" button is present.
    expect(find.text('Register Here'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:tryout/lib/screens/goals_screen.dart'; // Adjust path

void main() {
  testWidgets('adds goal to list on valid input', (tester) async {
    await tester.pumpWidget(MaterialApp(home: GoalsScreen()));
    await tester.pump();

    await tester.enterText(
        find.byWidgetPredicate((w) =>
            w is TextField && w.decoration?.labelText == 'Goal Name'),
        'Vacation');
    await tester.enterText(
        find.byWidgetPredicate((w) =>
            w is TextField && w.decoration?.labelText == 'Target Amount'),
        '1000');
    await tester.tap(find.text('Add Goal'));
    await tester.pump();

    expect(find.text('Vacation'), findsOneWidget);
  });
}

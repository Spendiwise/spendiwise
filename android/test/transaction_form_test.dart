import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:tryout/lib/screens/transaction_form.dart'; // Adjust path

void main() {
  testWidgets('shows error for empty amount', (tester) async {
    await tester.pumpWidget(MaterialApp(home: TransactionForm()));
    await tester.pump();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Amount required'), findsOneWidget);
  });
}

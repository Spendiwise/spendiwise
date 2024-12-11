import 'package:flutter/material.dart';
import '../screens/add_transaction_screen.dart';

typedef TransactionAddedCallback = void Function(Map<String, dynamic> newTransaction);

class AddTransactionFAB extends StatelessWidget {
  final TransactionAddedCallback onTransactionAdded;

  AddTransactionFAB({required this.onTransactionAdded});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.large(
      onPressed: () async {
        // Navigate to AddTransactionScreen and wait for the result
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddTransactionScreen()),
        );

        // If a new transaction is returned, call the callback
        if (result != null) {
          onTransactionAdded(result);
        }
      },
      child: Icon(Icons.add),
    );
  }
}

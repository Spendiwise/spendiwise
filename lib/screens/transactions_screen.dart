// transactions_screen.dart
import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transactions = [
    {'description': 'Groceries', 'amount': -50.75},
    {'description': 'Salary', 'amount': 2000.00},
    {'description': 'Coffee', 'amount': -5.50},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return ListTile(
          title: Text(transaction['description']),
          trailing: Text(
            transaction['amount'] >= 0
                ? '\$${transaction['amount']}'
                : '-\$${transaction['amount'].abs()}',
            style: TextStyle(
              color: transaction['amount'] >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
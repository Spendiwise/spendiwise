import 'package:flutter/material.dart';
import 'transaction_item.dart';

typedef DeleteTransactionCallback = void Function(int index);
typedef EditTransactionCallback = void Function(int index, Map<String, dynamic> transaction);

class TransactionList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final double balance;
  final DeleteTransactionCallback onDeleteTransaction;
  final EditTransactionCallback onEditTransaction;

  TransactionList({
    required this.transactions,
    required this.balance,
    required this.onDeleteTransaction,
    required this.onEditTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        // Use reversed index to show the last added transaction on top
        final reversedIndex = transactions.length - 1 - index;
        final transaction = transactions[reversedIndex];

        return TransactionItem(
          transaction: transaction,
          index: reversedIndex,
          onDeleteTransaction: (i) => onDeleteTransaction(i),
          onEditTransaction: (i, t) => onEditTransaction(i, t),
        );
      },
    );
  }
}

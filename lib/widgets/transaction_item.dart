import 'package:flutter/material.dart';

typedef OnEditTransactionCallback = void Function(int index, Map<String, dynamic> transaction);
typedef OnDeleteTransactionCallback = void Function(int index);

class TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final int index;
  final OnEditTransactionCallback onEditTransaction;
  final OnDeleteTransactionCallback onDeleteTransaction;

  TransactionItem({
    required this.transaction,
    required this.index,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = transaction['isIncome'] ? Colors.green : Colors.red;

    return Card(
      child: Row(
        children: [
          // Colored line on the left side
          Container(
            width: 5,
            height: 100,
            color: lineColor,
          ),
          Expanded(
            child: ListTile(
              title: Text(transaction['description']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount: \$${transaction['amount'].toStringAsFixed(2)}'),
                  Text('Category: ${transaction['category']}'),
                  Text('Date: ${transaction['date']}'),
                  Text('Type: ${transaction['isIncome'] ? 'Income' : 'Expense'}'),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEditTransaction(index, transaction);
                  } else if (value == 'delete') {
                    onDeleteTransaction(index);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

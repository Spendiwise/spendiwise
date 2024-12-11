import 'package:flutter/material.dart';
import '../controllers/transaction_search_delegate.dart';
import '../screens/add_transaction_screen.dart';

typedef TransactionsUpdatedCallback = void Function(List<Map<String, dynamic>> updatedTransactions, double updatedBalance);

class SearchTransactionButton extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final TransactionsUpdatedCallback onTransactionsUpdated;

  SearchTransactionButton({
    required this.transactions,
    required this.onTransactionsUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          showSearch(
            context: context,
            delegate: TransactionSearchDelegate(
              transactions,
              onEditTransaction: (originalIndex, updatedTransaction) {
                // When editing from search:
                // Replace the transaction
                final newTransactions = List<Map<String, dynamic>>.from(transactions);
                newTransactions[originalIndex] = updatedTransaction;
                // Recalculate balance
                double newBalance = newTransactions.fold(
                  0.0,
                      (sum, t) => sum + (t['isIncome'] ? t['amount'] : -t['amount']),
                );
                onTransactionsUpdated(newTransactions, newBalance);
              },
              onDeleteTransaction: (originalIndex) {
                final newTransactions = List<Map<String, dynamic>>.from(transactions);
                final transaction = newTransactions[originalIndex];
                double newBalance = newTransactions.fold(
                  0.0,
                      (sum, t) => sum + (t['isIncome'] ? t['amount'] : -t['amount']),
                );
                // Adjust balance after removing
                if (transaction['isIncome']) {
                  newBalance -= transaction['amount'];
                } else {
                  newBalance += transaction['amount'];
                }
                newTransactions.removeAt(originalIndex);
                onTransactionsUpdated(newTransactions, newBalance);
              },
              onNavigateToEditScreen: (context, transaction) async {
                final originalIndex = transactions.indexOf(transaction);
                final updatedTransaction = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTransactionScreen(transaction: transaction),
                  ),
                );
                if (updatedTransaction != null) {
                  final newTransactions = List<Map<String, dynamic>>.from(transactions);
                  newTransactions[originalIndex] = updatedTransaction;
                  double newBalance = newTransactions.fold(
                    0.0,
                        (sum, t) => sum + (t['isIncome'] ? t['amount'] : -t['amount']),
                  );
                  onTransactionsUpdated(newTransactions, newBalance);
                }
              },
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search),
            SizedBox(height: 8),
            Text('Search Transaction'),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../screens/add_transaction_screen.dart';

class TransactionUpdateResult {
  final List<Map<String, dynamic>> updatedTransactions;
  final double updatedBalance;

  TransactionUpdateResult({
    required this.updatedTransactions,
    required this.updatedBalance,
  });
}

// This function handles deleting a transaction
TransactionUpdateResult deleteTransactionController(
    List<Map<String, dynamic>> transactions, double balance, int index) {
  final transaction = transactions[index];
  if (transaction['isIncome']) {
    balance -= transaction['amount'];
  } else {
    balance += transaction['amount'];
  }

  transactions.removeAt(index);

  return TransactionUpdateResult(
    updatedTransactions: List<Map<String, dynamic>>.from(transactions),
    updatedBalance: balance,
  );
}

// This function handles editing a transaction
Future<TransactionUpdateResult?> editTransactionController(
    BuildContext context,
    List<Map<String, dynamic>> transactions,
    double balance,
    int index,
    ) async {
  final updatedTransaction = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddTransactionScreen(transaction: transactions[index]),
    ),
  );

  if (updatedTransaction != null) {
    transactions[index] = updatedTransaction;

    // Recalculate the balance
    double newBalance = transactions.fold(
      0.0,
          (sum, t) => sum + (t['isIncome'] ? t['amount'] : -t['amount']),
    );

    return TransactionUpdateResult(
      updatedTransactions: List<Map<String, dynamic>>.from(transactions),
      updatedBalance: newBalance,
    );
  }

  return null;
}

// This function handles adding a transaction
TransactionUpdateResult addTransactionController(
    List<Map<String, dynamic>> transactions,
    double balance,
    Map<String, dynamic> newTransaction,
    ) {
  transactions.add(newTransaction);
  if (newTransaction['isIncome']) {
    balance += newTransaction['amount'];
  } else {
    balance -= newTransaction['amount'];
  }

  return TransactionUpdateResult(
    updatedTransactions: List<Map<String, dynamic>>.from(transactions),
    updatedBalance: balance,
  );
}

// lib/controllers/transaction_controller.dart
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

// Deleting a transaction
TransactionUpdateResult deleteTransactionController(
    List<Map<String, dynamic>> transactions,
    double balance,
    int index) {
  final tx = transactions[index];
  // Ensure amount is double
  double amt = (tx['amount'] as num).toDouble();

  if (tx['isIncome'] as bool) {
    balance -= amt;
  } else {
    balance += amt;
  }

  transactions.removeAt(index);

  return TransactionUpdateResult(
    updatedTransactions: List<Map<String, dynamic>>.from(transactions),
    updatedBalance: balance,
  );
}

// Editing a transaction
Future<TransactionUpdateResult?> editTransactionController(
    BuildContext context,
    List<Map<String, dynamic>> transactions,
    double balance,
    int index) async {
  final updated = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(
      builder: (_) =>
          AddTransactionScreen(transaction: transactions[index]),
    ),
  );

  if (updated != null) {
    // Cast amount to double
    updated['amount'] = (updated['amount'] as num).toDouble();
    transactions[index] = updated;

    // Recalculate balance
    double newBalance = transactions.fold(
      0.0,
          (sum, t) => sum +
          ((t['isIncome'] as bool)
              ? (t['amount'] as num).toDouble()
              : -(t['amount'] as num).toDouble()),
    );

    return TransactionUpdateResult(
      updatedTransactions: List<Map<String, dynamic>>.from(transactions),
      updatedBalance: newBalance,
    );
  }

  return null;
}

// Adding a transaction
TransactionUpdateResult addTransactionController(
    List<Map<String, dynamic>> transactions,
    double balance,
    Map<String, dynamic> newTransaction) {
  // Cast amount
  double amt = (newTransaction['amount'] as num).toDouble();
  newTransaction['amount'] = amt;
  transactions.add(newTransaction);

  if (newTransaction['isIncome'] as bool) {
    balance += amt;
  } else {
    balance -= amt;
  }

  return TransactionUpdateResult(
    updatedTransactions: List<Map<String, dynamic>>.from(transactions),
    updatedBalance: balance,
  );
}

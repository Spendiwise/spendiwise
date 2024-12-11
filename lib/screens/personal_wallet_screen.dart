import 'package:flutter/material.dart';

// Widgets
import '../widgets/balance_section.dart';
import '../widgets/goals_button.dart';
import '../widgets/search_transaction_button.dart';
import '../widgets/transaction_list.dart';
import '../widgets/add_transaction_fab.dart';

// Controllers
import '../controllers/goal_controller.dart';
import '../controllers/transaction_controller.dart';

// Screens
import 'goal_screen.dart';
import 'add_transaction_screen.dart';

class PersonalWalletScreen extends StatefulWidget {
  @override
  _PersonalWalletScreenState createState() => _PersonalWalletScreenState();
}

class _PersonalWalletScreenState extends State<PersonalWalletScreen> {
  double balance = 1500.50;
  List<Map<String, dynamic>> transactions = []; // Store transactions here
  List<Map<String, dynamic>> goals = [
    {'title': 'Save for Vacation', 'target': 5000.0, 'progress': 2000.0},
    {'title': 'Buy a New Laptop', 'target': 1500.0, 'progress': 500.0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Personal Wallet'),
      ),
      body: Column(
        children: [
          // Balance section
          BalanceSection(balance: balance),
          SizedBox(height: 16),
          // Row for buttons placed horizontally
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GoalsButton(
                  onGoalsUpdated: (updatedGoals) {
                    // Use the controller function to update goals
                    setState(() {
                      goals = updateGoalsController(updatedGoals);
                    });
                  },
                  goals: goals,
                  balance: balance,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SearchTransactionButton(
                  transactions: transactions,
                  onTransactionsUpdated: (updatedTransactions, updatedBalance) {
                    setState(() {
                      transactions = updatedTransactions;
                      balance = updatedBalance;
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
            ],
          ),

          if (transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Transactions list
          Expanded(
            child: TransactionList(
              transactions: transactions,
              balance: balance,
              onDeleteTransaction: (index) {
                // Using the transaction_controller method
                final result = deleteTransactionController(
                    transactions, balance, index);
                setState(() {
                  transactions = result.updatedTransactions;
                  balance = result.updatedBalance;
                });
              },
              onEditTransaction: (index, editedTransaction) async {
                // Navigate and edit using the controller function
                final result = await editTransactionController(
                  context,
                  transactions,
                  balance,
                  index,
                );

                if (result != null) {
                  setState(() {
                    transactions = result.updatedTransactions;
                    balance = result.updatedBalance;
                  });
                }
              },
            ),
          ),
        ],
      ),

      floatingActionButton: AddTransactionFAB(
        onTransactionAdded: (newTransaction) {
          // Add new transaction and update balance using controller
          final result = addTransactionController(transactions, balance, newTransaction);
          setState(() {
            transactions = result.updatedTransactions;
            balance = result.updatedBalance;
          });
        },
      ),
    );
  }
}

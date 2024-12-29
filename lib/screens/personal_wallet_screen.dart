import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tryout/widgets/forecasting_button.dart';

// Widgets
import '../widgets/balance_section.dart';
import '../widgets/goals_button.dart';
import '../widgets/search_transaction_button.dart';
import '../widgets/transaction_list.dart';
import '../widgets/add_transaction_fab.dart';
import '../widgets/events_button.dart';

// Controllers
import '../controllers/goal_controller.dart';
import '../controllers/transaction_controller.dart';

// Screens
import 'notifications_screen.dart';

class PersonalWalletScreen extends StatefulWidget {
  @override
  _PersonalWalletScreenState createState() => _PersonalWalletScreenState();
}

class _PersonalWalletScreenState extends State<PersonalWalletScreen> with AutomaticKeepAliveClientMixin {
  double balance = 0.0; // Initial balance
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> goals = [
    {'title': 'Save for Vacation', 'target': 5000.0, 'progress': 2000.0},
    {'title': 'Buy a New Laptop', 'target': 1500.0, 'progress': 500.0},
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchBalanceFromFirebase(); // Fetch balance on initialization
  }

  Future<void> _fetchBalanceFromFirebase() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      String uid = user.uid;
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        setState(() {
          balance = (userDoc['balance'] ?? 0.0).toDouble(); // Ensure balance is double
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Balance not found for user.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching balance: ${e.toString()}")),
      );
    }
  }

  Future<void> _updateBalanceInFirestore() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      String uid = user.uid;
      await _firestore.collection('users').doc(uid).update({'balance': balance});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating balance: ${e.toString()}")),
      );
    }
  }

  void _onTransactionAdded(Map<String, dynamic> newTransaction) {
    final result = addTransactionController(transactions, balance, newTransaction);

    setState(() {
      transactions = result.updatedTransactions;
      balance = result.updatedBalance;
    });

    // Update balance in Firestore
    _updateBalanceInFirestore();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Personal Wallet'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          BalanceSection(balance: balance),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GoalsButton(
                  onGoalsUpdated: (updatedGoals) {
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

                    _updateBalanceInFirestore();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: EventsButton(),
              ),
              Expanded(
                child: ForecastingButton(),
              ),
            ],
          ),
          if (transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Transaction History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: TransactionList(
              transactions: transactions,
              balance: balance,
              onDeleteTransaction: (index) {
                final result = deleteTransactionController(transactions, balance, index);
                setState(() {
                  transactions = result.updatedTransactions;
                  balance = result.updatedBalance;
                });

                _updateBalanceInFirestore();
              },
              onEditTransaction: (index, editedTransaction) async {
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

                  _updateBalanceInFirestore();
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AddTransactionFAB(
        onTransactionAdded: _onTransactionAdded,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

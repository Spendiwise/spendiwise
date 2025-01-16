import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:http/http.dart' as http; // For making HTTP requests
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

  Map<String, dynamic>? forecastData; // Store forecast data

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _listenToBalanceChanges(); // Listen for balance changes in real-time
    _fetchTransactions(); // Fetch transactions from Firestore
    _fetchForecastData(); // Optionally, fetch forecast data
  }

  // Real-time listener for balance changes
  void _listenToBalanceChanges() {
    final User? user = _auth.currentUser;
    if (user == null) return; // No user logged in

    String uid = user.uid;
    _firestore.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          balance = (snapshot['balance'] ?? 0.0).toDouble(); // Update balance with Firestore data
        });
      } else {
        print('User document not found');
      }
    });
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

  Future<void> _fetchTransactions() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Fetch transactions where the 'user_id' reference matches the current user's reference
      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: _firestore.collection('users').doc(user.uid))
          .get();

      List<Map<String, dynamic>> fetchedTransactions = [];
      double fetchedBalance = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure document ID is included
        fetchedTransactions.add(data);
        fetchedBalance += data['amount'];
      }

      setState(() {
        transactions = fetchedTransactions;
        balance = fetchedBalance;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
    }
  }

  Future<void> _fetchForecastData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Example API URL (replace with your actual API endpoint)
      final String apiUrl = 'http://10.0.2.2:5000/forecast';

      // JSON payload
      final Map<String, dynamic> payload = {
        "user_id": user.uid,
        "category": "Groceries",
        "duration": "month",
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        setState(() {
          forecastData = jsonDecode(response.body); // Decode and store forecast data
        });
      } else {
        throw Exception('Failed to fetch forecast data: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching forecast data: ${e.toString()}")),
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

  Future<void> deleteTransactionFromFirestore(String transactionId) async {
    try {
      print("Attempting to delete transaction with ID: $transactionId");
      await _firestore.collection('transactions').doc(transactionId).delete();
      print("Transaction deleted successfully");
    } catch (e) {
      print("Error deleting transaction: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting transaction: ${e.toString()}")),
      );
    }
  }

  Widget _buildForecastSection() {
    if (forecastData == null || forecastData!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No forecast data available.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forecast Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...forecastData!.entries.map((entry) {
              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.bar_chart, color: Colors.blue),
                  title: Text(entry.key),
                  subtitle: Text('Value: ${entry.value}'),
                ),
              );
            }).toList(),
          ],
        ),
      );
    }
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
          IconButton(
            icon: Icon(Icons.cloud),
            onPressed: _fetchForecastData, // Trigger forecast data fetch
          ),
        ],
      ),
      body: Column(
        children: [
          BalanceSection(balance: balance),
          SizedBox(height: 16),
          _buildForecastSection(),
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
              onDeleteTransaction: (index) async {
                final transactionToDelete = transactions[index];
                final transactionId = transactionToDelete['id'];

                if (transactionId == null) {
                  print("Transaction ID is null");
                  return;
                }

                // Optimistic UI update
                final result = deleteTransactionController(transactions, balance, index);
                setState(() {
                  transactions = result.updatedTransactions;
                  balance = result.updatedBalance;
                });

                // Attempt Firestore deletion
                await deleteTransactionFromFirestore(transactionId);

                // Update balance in Firestore
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

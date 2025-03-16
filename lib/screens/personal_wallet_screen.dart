import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:http/http.dart' as http; // For making HTTP requests
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
  List<Map<String, dynamic>> goals = [];

  Map<String, dynamic>? forecastData; // Store forecast data

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userEmail = FirebaseAuth.instance.currentUser?.email ?? "unknown@example.com";

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
    if (user == null) return;

    String uid = user.uid;
    _firestore.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          balance = (snapshot['balance'] ?? 0.0).toDouble(); // ✅ Only fetch balance from Firestore
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

      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: _firestore.collection('users').doc(user.uid))
          .get();

      List<Map<String, dynamic>> fetchedTransactions = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure document ID is included
        fetchedTransactions.add(data);
      }

      setState(() {
        transactions = fetchedTransactions;
        // ❌ REMOVE balance update here!
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

  Future<void> onAddTransaction(Map<String, dynamic> newTransaction) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final userRef = _firestore.collection('users').doc(user.uid);

      // Ensure amount is stored as a double
      double amount = (newTransaction['amount'] as num).toDouble();

      // Create a new transaction with proper types
      final transactionData = {
        ...newTransaction,
        'amount': amount, // Ensure it's a double
        'user_id': userRef, // Firestore DocumentReference
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add the transaction to Firestore
      final docRef = await _firestore.collection('transactions').add(transactionData);

      // Retrieve the new transaction with its generated ID
      final addedTransaction = {...transactionData, 'id': docRef.id};

      // Use the transaction controller to update the balance
      final result = addTransactionController(transactions, balance, addedTransaction);

      // Update UI state
      setState(() {
        transactions = result.updatedTransactions;
        balance = result.updatedBalance;
      });

      // Update balance in Firestore
      await _updateBalanceInFirestore();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding transaction: ${e.toString()}")),
      );
    }
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
              final User? user = _auth.currentUser;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(userEmail: user.email ?? 'Unknown'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User not logged in')),
                );
              }
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
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GoalsButton(
                  balance: balance,
                  email: userEmail ?? "unknown@example.com",
                  goalFlag: 0,
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
        onTransactionAdded: onAddTransaction,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
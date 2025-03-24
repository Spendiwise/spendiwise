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
import '../widgets/automatic_transaction_button.dart';
// Controllers
import '../controllers/goal_controller.dart';
import '../controllers/transaction_controller.dart';
// Screens
import 'notifications_screen.dart';
import 'forecasting_screen.dart';

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
    _listenToBalanceChanges();
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
        double fetchedBalance = (snapshot['balance'] ?? 0.0).toDouble();
        print("Balance fetched from Firestore: $fetchedBalance");
        setState(() {
          balance = (snapshot['balance'] ?? 0.0).toDouble();
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
      print("Updating balance in Firestore: $balance");

      await _firestore.collection('users').doc(uid).update({'balance': balance});

      print("Balance updated successfully in Firestore.");
    } catch (error) { // ✅ Change 'e' to 'error'
      print("Error updating balance in Firestore: $error"); // ✅ Now 'error' is recognized
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating balance: ${error.toString()}")),
      );
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final DocumentReference userRef = _firestore.collection('users').doc(user.uid); // ✅ Create userRef
      print("Fetching transactions for user: ${userRef.path}");
      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userRef)
          .get();
      print("Found ${snapshot.docs.length} transactions.");
      List<Map<String, dynamic>> fetchedTransactions = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure document ID is included
        fetchedTransactions.add(data);
      }

      setState(() {
        transactions = fetchedTransactions;
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

      final DocumentReference userRef = _firestore.collection('users').doc(user.uid);

      double amount = (newTransaction['amount'] as num).toDouble();
      bool isIncome = newTransaction['isIncome'] as bool;

      final transactionData = {
        ...newTransaction,
        'amount': amount,
        'user_id': userRef,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('transactions').add(transactionData);
      final addedTransaction = {...transactionData, 'id': docRef.id};

      print("Transaction successfully written with ID: ${docRef.id}");

      // Wait for Firestore to confirm
    await docRef.get().then((docSnapshot) {
      if (docSnapshot.exists) {
        print("Transaction confirmed in Firestore: ${docSnapshot.data()}");
      } else {
        print("Transaction not found in Firestore!");
      }
    });
      print("Transaction added: $addedTransaction");

      final result = addTransactionController(transactions, balance, addedTransaction);
      
      print("Before update - Transactions: ${transactions.length}, Balance: $balance");

      setState(() {
        transactions = result.updatedTransactions;
        balance = result.updatedBalance;
      });

      // ✅ Ensure the state update has completed before printing
      Future.delayed(Duration(milliseconds: 100), () {
        print("After update - Transactions: ${transactions.length}, Balance: $balance");
      });

      await _updateBalanceInFirestore(); 

    } catch (e) {
      print("Error adding transaction: $e");
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

            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ForecastingScreen()),
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
          SizedBox(height: 16),
          // Automatic Transaction Button
          AutomaticTransactionButton(),
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
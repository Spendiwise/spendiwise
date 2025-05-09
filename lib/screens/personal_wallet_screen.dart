// lib/screens/personal_wallet.dart
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

class _PersonalWalletScreenState extends State<PersonalWalletScreen>
    with AutomaticKeepAliveClientMixin {
  double balance = 0.0; // Initial balance
  Map<String, dynamic>? forecastData;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userEmail =
      FirebaseAuth.instance.currentUser?.email ?? "unknown@example.com";

  @override
  void initState() {
    super.initState();
    _listenToBalanceChanges();
    _fetchForecastData();
  }

  // Real-time listener for balance changes
  void _listenToBalanceChanges() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore.collection('users').doc(user.uid).snapshots().listen((snap) {
      if (snap.exists) {
        final data = snap.data()!;
        // Ensure num → double
        final fetchedBalance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        setState(() {
          balance = fetchedBalance;
        });
      }
    });
  }

  Future<void> _updateBalanceInFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .update({'balance': balance});
  }

  Future<void> _fetchForecastData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final apiUrl = 'http://10.0.2.2:5000/forecast';
      final payload = {
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
          forecastData = jsonDecode(response.body);
        });
      } else {
        throw Exception('Failed to fetch forecast data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching forecast data: $e")),
      );
    }
  }

  Future<void> onAddTransaction(Map<String, dynamic> newTransaction) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Prepare data
      double amt = (newTransaction['amount'] as num).toDouble();
      final transactionData = {
        ...newTransaction,
        'amount': amt,
        'user_id': _firestore.collection('users').doc(user.uid),
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Write to Firestore
      final docRef =
      await _firestore.collection('transactions').add(transactionData);

      // Update balance by letting _listenToBalanceChanges pick it up
      // (balance is automatically synced)
      // But if you need to adjust server-side, you can:
      // final newBalance = balance + (newTransaction['isIncome'] as bool ? amt : -amt);
      // await _firestore.collection('users').doc(user.uid).update({'balance': newBalance});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding transaction: $e")),
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
    super.build(context);
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Personal Wallet'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationsScreen(userEmail: user.email!),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.cloud),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ForecastingScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Dynamic balance display
          BalanceSection(balance: balance),

          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GoalsButton(
                  balance: balance,
                  email: userEmail,
                  goalFlag: 0,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SearchTransactionButton(
                  transactions: [], // Now unused, kept for compatibility
                  onTransactionsUpdated: (txs, bal) {
                    // no-op: list is real-time
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 16),
          AutomaticTransactionButton(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Transaction History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: TransactionList(),
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

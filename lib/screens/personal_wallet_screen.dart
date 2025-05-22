// lib/screens/personal_wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:badges/badges.dart' as badges; // For notification badge

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

  /// Listens in real time to the user's balance document
  void _listenToBalanceChanges() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore.collection('users').doc(user.uid).snapshots().listen((snap) {
      if (snap.exists) {
        final data = snap.data()!;
        // Convert num to double safely
        final fetchedBalance =
            (data['balance'] as num?)?.toDouble() ?? 0.0;
        setState(() {
          balance = fetchedBalance;
        });
      }
    });
  }

  /// Fetches forecast data from external service
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

  /// Optional: callback for adding a transaction outside FAB
  Future<void> onAddTransaction(Map<String, dynamic> newTransaction) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      double amt = (newTransaction['amount'] as num).toDouble();
      final transactionData = {
        ...newTransaction,
        'amount': amt,
        'user_id': _firestore.collection('users').doc(user.uid),
        'timestamp': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('transactions').add(transactionData);
      // Balance will update via listener
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding transaction: $e")),
      );
    }
  }

  /// Builds the forecast section UI
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
          // Notification icon with unread badge
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notification')
                .where('email', isEqualTo: userEmail)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount =
              snapshot.hasData ? snapshot.data!.docs.length : 0;
              return IconButton(
                icon: badges.Badge(
                  position:
                  badges.BadgePosition.topEnd(top: -6, end: -6),
                  showBadge: unreadCount > 0,
                  badgeContent: Text(
                    '$unreadCount',
                    style: TextStyle(
                        color: Colors.white, fontSize: 10),
                  ),
                  child: Icon(Icons.notifications),
                ),
                onPressed: () {
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(
                            userEmail: user.email!),
                      ),
                    );
                  }
                },
              );
            },
          ),

          // Forecast icon
          IconButton(
            icon: Icon(Icons.cloud),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ForecastingScreen()),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // Balance display
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
                  transactions: [],
                  onTransactionsUpdated: (txs, bal) {},
                ),
              ),
            ],
          ),

          SizedBox(height: 16),
          AutomaticTransactionButton(),

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Transaction History',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: TransactionList(),
          ),
        ],
      ),

      // Floating action button for adding transactions
      floatingActionButton: AddTransactionFAB(
        onTransactionAdded: onAddTransaction,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

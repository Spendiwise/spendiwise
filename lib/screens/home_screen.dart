import 'package:flutter/material.dart';
import 'add_transaction_screen.dart';
import 'goal_screen.dart'; // Import the Goal Page

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double balance = 1500.50;
  List<Map<String, dynamic>> transactions = []; // Store transactions here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spendiwise'),
        actions: [
          IconButton(
            icon: Icon(Icons.flag), // Icon for navigating to the Goal Page
            tooltip: 'Manage Goals',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GoalScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Balance section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.green,
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  'Your Balance',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  '\$${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Transactions list
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return ListTile(
                  title: Text(transaction['description']),
                  subtitle: Text('\$${transaction['amount'].toStringAsFixed(2)}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to AddTransactionScreen and wait for the result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransactionScreen()),
          );

          // Add the transaction to the list and update the balance
          if (result != null) {
            setState(() {
              transactions.add(result);
              balance += result['amount']; // Adjust balance
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

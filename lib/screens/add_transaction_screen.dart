import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction; // Accepts a transaction for editing

  AddTransactionScreen({this.transaction}); // Constructor

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String category = 'Food'; // Default category
  bool isIncome = false; // Default: expense
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    // If editing an existing transaction, populate fields
    if (widget.transaction != null) {
      descriptionController.text = widget.transaction!['description'];
      amountController.text = widget.transaction!['amount'].toString();
      category = widget.transaction!['category'];
      isIncome = widget.transaction!['isIncome'];
    }
  }

  Future<void> _updateUserBalance(double newBalance) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      await _firestore.collection('users').doc(user.uid).update({
        'balance': newBalance,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Balance updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating balance: ${e.toString()}")),
      );
    }
  }

  Future<void> _addTransactionToFirestore(Map<String, dynamic> transactionData) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final userRef = _firestore.collection('users').doc(user.uid);

      final transaction = {
        'amount': transactionData['amount'],
        'category': transactionData['category'],
        'date': DateTime.now(),
        'description': transactionData['description'],
        'modified_at': DateTime.now(),
        'isIncome': transactionData['isIncome'],
        'user_id': userRef,
      };

      // Add transaction
      await _firestore.collection('transactions').add(transaction);

      // Fetch current balance
      final DocumentSnapshot userDoc = await userRef.get();
      double currentBalance = userDoc.exists ? userDoc['balance'] ?? 0.0 : 0.0;

      // Update balance
      double updatedBalance = currentBalance + (transactionData['isIncome'] ? transactionData['amount'] : -transactionData['amount']);
      await _updateUserBalance(updatedBalance);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transaction added successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding transaction: ${e.toString()}")),
      );
    }
  }

  Future<void> _updateTransactionInFirestore(String transactionId, Map<String, dynamic> updatedData) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final docRef = _firestore.collection('transactions').doc(transactionId);

      // Fetch old transaction details
      final oldTransaction = await docRef.get();
      if (!oldTransaction.exists) throw Exception("Transaction not found");

      double oldAmount = oldTransaction['amount'];
      bool oldIsIncome = oldTransaction['isIncome'];

      // Update transaction in Firestore
      await docRef.update(updatedData);

      // Adjust user balance
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      double currentBalance = userDoc.exists ? userDoc['balance'] ?? 0.0 : 0.0;

      // Recalculate balance
      double updatedBalance = currentBalance - (oldIsIncome ? oldAmount : -oldAmount) + (updatedData['isIncome'] ? updatedData['amount'] : -updatedData['amount']);

      await _updateUserBalance(updatedBalance);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transaction updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating transaction: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount'),
            ),
            DropdownButton<String>(
              value: category,
              onChanged: (newValue) {
                setState(() {
                  category = newValue!;
                });
              },
              items: <String>['Food', 'Entertainment', 'Salary', 'Bills']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            Row(
              children: [
                Text('Expense'),
                Switch(
                  value: isIncome,
                  onChanged: (value) {
                    setState(() {
                      isIncome = value;
                    });
                  },
                ),
                Text('Income'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final description = descriptionController.text;
                final amount = double.tryParse(amountController.text);

                if (description.isNotEmpty && amount != null) {
                  final transactionData = {
                    'description': description,
                    'amount': amount,
                    'category': category,
                    'isIncome': isIncome,
                    'modified_at': DateTime.now(),
                  };

                  if (widget.transaction != null) {
                    // Editing existing transaction
                    await _updateTransactionInFirestore(widget.transaction!['id'], transactionData);
                  } else {
                    // Adding new transaction
                    await _addTransactionToFirestore(transactionData);
                  }

                  Navigator.pop(context); // Go back
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill in all fields")),
                  );
                }
              },
              child: Text(widget.transaction != null ? 'Update Transaction' : 'Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

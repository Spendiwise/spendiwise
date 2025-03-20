import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction; // Accepts a transaction for editing
  final String? groupId; // Added group ID to track if it's a group transaction

  AddTransactionScreen({this.transaction, this.groupId}); // Constructor

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

  Future<void> _addTransactionToFirestore(Map<String, dynamic> transactionData, {String? groupId}) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      CollectionReference transactionCollection;
      DocumentReference balanceRef;

      if (groupId != null) {
        // Add transaction to the group wallet
        transactionCollection = FirebaseFirestore.instance
            .collection('wallets')
            .doc(groupId)
            .collection('transactions');

        balanceRef = FirebaseFirestore.instance.collection('wallets').doc(groupId);
      } else {
        // Add transaction to personal wallet
        transactionCollection = FirebaseFirestore.instance
            .collection('transactions')
            .doc(user.uid)
            .collection('transactions');

        balanceRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      }

      final transaction = {
        'amount': (transactionData['amount'] as num).toDouble(),
        'category': transactionData['category'],
        'date': DateTime.now(),
        'description': transactionData['description'],
        'modified_at': DateTime.now(),
        'isIncome': transactionData['isIncome'],
        'user_id': user.uid, // Track who made the transaction
        'group_id': groupId, // Store group ID if applicable
      };

      await transactionCollection.add(transaction);

      // Update balance for the respective wallet (group or personal)
      final balanceDoc = await balanceRef.get();
      double currentBalance = balanceDoc.exists ? (balanceDoc['balance'] ?? 0.0) : 0.0;
      double newBalance = currentBalance + (transaction['isIncome'] ? transaction['amount'] : -transaction['amount']);

      await balanceRef.update({'balance': newBalance});

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

      double oldAmount = (oldTransaction['amount'] as num).toDouble();
      bool oldIsIncome = oldTransaction['isIncome'];

      // Update transaction in Firestore
      await docRef.update(updatedData);

      // Fetch current balance
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      double currentBalance = userDoc.exists ? (userDoc['balance'] ?? 0.0) : 0.0;

      // Correct balance update based on income/expense changes
      double updatedAmount = (updatedData['amount'] as num).toDouble();
      bool updatedIsIncome = updatedData['isIncome'];

      double newBalance = currentBalance;

      // If the income/expense type changes, reverse old effect and apply new one
      if (oldIsIncome != updatedIsIncome) {
        newBalance -= oldIsIncome ? oldAmount : -oldAmount; // Remove old transaction impact
        newBalance += updatedIsIncome ? updatedAmount : -updatedAmount; // Add new impact
      } else {
        // If the type is the same, just adjust for the amount difference
        newBalance += updatedIsIncome
            ? (updatedAmount - oldAmount)
            : (oldAmount - updatedAmount);
      }

      await _updateUserBalance(newBalance);

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
                    // Editing an existing transaction
                    await _updateTransactionInFirestore(widget.transaction!['id'], transactionData);
                  } else {
                    // Check if the transaction is for a group wallet or personal wallet
                    await _addTransactionToFirestore(transactionData, groupId: widget.groupId);
                  }

                  Navigator.pop(context); // Go back after saving
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
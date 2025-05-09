// lib/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction; // Accepts a transaction for editing
  final String? groupId; // Track if it's a group transaction

  AddTransactionScreen({this.transaction, this.groupId});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  String category = 'Food';
  bool isIncome = false;
  late DateTime _selectedDate;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      descriptionController.text = widget.transaction!['description'] as String;
      double amt = (widget.transaction!['amount'] as num).toDouble();
      amountController.text = amt.toString();
      category = widget.transaction!['category'] as String;
      isIncome = widget.transaction!['isIncome'] as bool;

      final rawDate = widget.transaction!['date'];
      if (rawDate is Timestamp) {
        _selectedDate = rawDate.toDate();
      } else if (rawDate is DateTime) {
        _selectedDate = rawDate;
      } else {
        _selectedDate = DateTime.now();
      }
    } else {
      _selectedDate = DateTime.now();
    }

    dateController.text =
    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  Future<void> _updateUserBalance(double newBalance) async {
    try {
      final user = _auth.currentUser;
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

  Future<void> _addTransactionToFirestore(
      Map<String, dynamic> transactionData,
      {String? groupId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      CollectionReference txCol;
      DocumentReference balanceRef;

      if (groupId != null) {
        // Add to group wallet
        txCol = _firestore
            .collection('wallets')
            .doc(groupId)
            .collection('transactions');
        balanceRef = _firestore.collection('wallets').doc(groupId);
      } else {
        // Add to personal wallet
        txCol = _firestore
            .collection('transactions')
            .doc(user.uid)
            .collection('transactions');
        balanceRef = _firestore.collection('users').doc(user.uid);
      }

      double amt = (transactionData['amount'] as num).toDouble();

      final tx = {
        'description': transactionData['description'],
        'amount': amt,
        'category': transactionData['category'],
        'isIncome': transactionData['isIncome'],
        'date': _selectedDate,
        'modified_at': DateTime.now(),
        'user_id': user.uid,
        'group_id': groupId,
      };

      await txCol.add(tx);

      final docSnap = await balanceRef.get();
      final data = docSnap.data() as Map<String, dynamic>?; // cast here
      double currentBalance = (data?['balance'] as num?)?.toDouble() ?? 0.0;
      double newBalance = currentBalance +
          ((tx['isIncome'] as bool) ? (tx['amount'] as double) : -(tx['amount'] as double));

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

  Future<void> _updateTransactionInFirestore(
      String transactionId, Map<String, dynamic> updatedData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final docRef = _firestore.collection('transactions').doc(transactionId);
      final oldSnap = await docRef.get();
      if (!oldSnap.exists) throw Exception("Transaction not found");

      double oldAmount = (oldSnap['amount'] as num).toDouble();
      bool oldIsIncome = oldSnap['isIncome'] as bool;

      updatedData['amount'] = (updatedData['amount'] as num).toDouble();
      updatedData['date'] = _selectedDate;

      await docRef.update(updatedData);

      final userSnap = await _firestore.collection('users').doc(user.uid).get();
      final userData = userSnap.data() as Map<String, dynamic>?; // cast here
      double currentBalance = (userData?['balance'] as num?)?.toDouble() ?? 0.0;

      double newAmount = updatedData['amount'] as double;
      bool newIsIncome = updatedData['isIncome'] as bool;

      double newBalance = currentBalance;
      if (oldIsIncome != newIsIncome) {
        newBalance -= oldIsIncome ? oldAmount : -oldAmount;
        newBalance += newIsIncome ? newAmount : -newAmount;
      } else {
        newBalance += oldIsIncome
            ? (newAmount - oldAmount)
            : (oldAmount - newAmount);
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
        title: Text(
            widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Date'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    dateController.text =
                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),
            DropdownButton<String>(
              value: category,
              onChanged: (v) => setState(() => category = v!),
              items: <String>['Food', 'Entertainment', 'Salary', 'Bills']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
            ),
            Row(
              children: [
                Text('Expense'),
                Switch(
                  value: isIncome,
                  onChanged: (v) => setState(() => isIncome = v),
                ),
                Text('Income'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final desc = descriptionController.text;
                final amt = double.tryParse(amountController.text);

                if (desc.isNotEmpty && amt != null) {
                  final data = {
                    'description': desc,
                    'amount': amt,
                    'category': category,
                    'isIncome': isIncome,
                    'modified_at': DateTime.now(),
                  };

                  if (widget.transaction != null) {
                    await _updateTransactionInFirestore(
                        widget.transaction!['id'] as String, data);
                  } else {
                    await _addTransactionToFirestore(data,
                        groupId: widget.groupId);
                  }

                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill in all fields")),
                  );
                }
              },
              child: Text(widget.transaction != null
                  ? 'Update Transaction'
                  : 'Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

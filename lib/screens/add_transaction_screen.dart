// lib/screens/add_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tryout/controllers/check_goal_milestones.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction;
  final String? groupId;

  AddTransactionScreen({this.transaction, this.groupId});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  static const List<String> _categories = [
    'groceries',
    'dining',
    'gifts',
    'transportation',
    'utilities',
    'shopping',
    'entertainment',
    'health',
    'travel',
    'fuel',
    'education',
    'auto',
    'bills',
    'salary',
    'refund',
    'others',
  ];

  String category = _categories.first;
  bool isIncome = false;
  late DateTime _selectedDate;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      final tx = widget.transaction!;
      descriptionController.text = tx['description'] as String;
      double amt = (tx['amount'] as num).toDouble();
      amountController.text = amt.toString();

      final cat = tx['category'] as String;
      category = _categories.contains(cat) ? cat : _categories.first;

      isIncome = tx['isIncome'] as bool;

      final rawDate = tx['date'];
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
    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  Future<void> _addTransactionToFirestore(
      Map<String, dynamic> transactionData, {
        String? groupId,
      }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      late CollectionReference txCol;
      late DocumentReference balanceRef;
      if (groupId != null) {
        txCol = _firestore
            .collection('wallets')
            .doc(groupId)
            .collection('transactions');
        balanceRef = _firestore.collection('wallets').doc(groupId);
      } else {
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
      final data = docSnap.data() as Map<String, dynamic>?;
      double currentBalance = (data?['balance'] as num?)?.toDouble() ?? 0.0;

      double newBalance = currentBalance + (isIncome ? amt : -amt);
      await balanceRef.update({'balance': newBalance});

      Navigator.pop(context);

      checkGoalMilestones(
        balance: newBalance,
        email: user.email!,
        groupId: groupId,
        goalFlag: groupId == null ? 0 : 1,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding transaction: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction != null ? 'Edit Transaction' : 'Add Transaction',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-'
                        '${picked.day.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            DropdownButton<String>(
              value: category,
              onChanged: (v) => setState(() => category = v!),
              items: _categories
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Expense'),
                Switch(
                  value: isIncome,
                  onChanged: (v) => setState(() => isIncome = v),
                ),
                Text('Income'),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                final desc = descriptionController.text.trim();
                final amt = double.tryParse(amountController.text.trim());
                if (desc.isNotEmpty && amt != null) {
                  _addTransactionToFirestore({
                    'description': desc,
                    'amount': amt,
                    'category': category,
                    'isIncome': isIncome,
                  }, groupId: widget.groupId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill in all fields")),
                  );
                }
              },
              child: Text(
                widget.transaction != null
                    ? 'Update Transaction'
                    : 'Add Transaction',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

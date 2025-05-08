// review_transactions_screen.dart

import 'package:flutter/material.dart';
import 'text_parser.dart';
import 'firebase_service.dart';
import '../../screens/main_wallet_screen.dart';


class ReviewTransactionsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  const ReviewTransactionsScreen({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  State<ReviewTransactionsScreen> createState() =>
      _ReviewTransactionsScreenState();
}

class _ReviewTransactionsScreenState extends State<ReviewTransactionsScreen> {
  late List<TextEditingController> _dateControllers;
  late List<TextEditingController> _descriptionControllers;
  late List<TextEditingController> _amountControllers;
  late List<TextEditingController> _categoryControllers;
  late List<bool> _isIncomeList;

  @override
  void initState() {
    super.initState();
    _dateControllers = widget.transactions
        .map((t) => TextEditingController(text: t.date))
        .toList();
    _descriptionControllers = widget.transactions
        .map((t) => TextEditingController(text: t.description))
        .toList();
    _amountControllers = widget.transactions
        .map((t) => TextEditingController(text: t.amount.toStringAsFixed(2)))
        .toList();
    _categoryControllers = widget.transactions
        .map((t) => TextEditingController(text: t.category))
        .toList();
    _isIncomeList = widget.transactions.map((t) => t.isIncome).toList();
  }

  @override
  void dispose() {
    for (var c in [
      ..._dateControllers,
      ..._descriptionControllers,
      ..._amountControllers,
      ..._categoryControllers
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    // Build edited list from user inputs
    final edited = <Transaction>[];
    for (int i = 0; i < widget.transactions.length; i++) {
      final date = _dateControllers[i].text.trim();
      final desc = _descriptionControllers[i].text.trim();
      final amount = double.tryParse(
          _amountControllers[i].text.replaceAll(',', '.')) ??
          0.0;
      final category = _categoryControllers[i].text.trim();
      final isIncome = _isIncomeList[i];

      edited.add(Transaction(
        date: date,
        description: desc,
        amount: amount,
        isIncome: isIncome,
        category: category,
      ));
    }

    // Save to Firebase
    try {
      await addAutomaticTransactions(edited);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Success'),
          content: Text('${edited.length} transactions saved.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                // then navigate to MainWalletScreen and clear backstack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => MainWalletScreen(),
                  ),
                      (route) => false,
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review & Edit Transactions'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: widget.transactions.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _dateControllers[index],
                    decoration: InputDecoration(labelText: 'Date'),
                  ),
                  TextField(
                    controller: _descriptionControllers[index],
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: _amountControllers[index],
                    decoration: InputDecoration(labelText: 'Amount'),
                    keyboardType:
                    TextInputType.numberWithOptions(decimal: true),
                  ),
                  TextField(
                    controller: _categoryControllers[index],
                    decoration: InputDecoration(labelText: 'Category'),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Type:'),
                      SizedBox(width: 16),
                      DropdownButton<bool>(
                        value: _isIncomeList[index],
                        items: [
                          DropdownMenuItem(
                            value: false,
                            child: Text('Expense'),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Text('Income'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _isIncomeList[index] = value!);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ElevatedButton(
            onPressed: _saveAll,
            style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16)),
            child: Text('Save All'),
          ),
        ),
      ),
    );
  }
}

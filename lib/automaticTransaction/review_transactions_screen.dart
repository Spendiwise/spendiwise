// lib/screens/review_transactions_screen.dart
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'text_parser.dart';
import '../screens/main_wallet_screen.dart';
import 'category_inference.dart';

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
  late List<TextEditingController> _dateCtrls;
  late List<TextEditingController> _descCtrls;
  late List<TextEditingController> _amountCtrls;
  late List<TextEditingController> _categoryCtrls;
  late List<bool> _isIncomeList;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadAndInit();
  }

  Future<void> _loadAndInit() async {
    await CategoryInference.init();

    _dateCtrls = widget.transactions
        .map((t) => TextEditingController(text: t.date))
        .toList();
    _descCtrls = widget.transactions
        .map((t) => TextEditingController(text: t.description))
        .toList();
    _amountCtrls = widget.transactions
        .map((t) =>
        TextEditingController(text: t.amount.toStringAsFixed(2)))
        .toList();
    _categoryCtrls = widget.transactions
        .map((t) => TextEditingController(
        text: CategoryInference.inferCategory(t.description)))
        .toList();
    _isIncomeList = widget.transactions.map((t) => t.isIncome).toList();

    setState(() {
      _initialized = true;
    });
  }

  @override
  void dispose() {
    for (final c in [
      ..._dateCtrls,
      ..._descCtrls,
      ..._amountCtrls,
      ..._categoryCtrls,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    final edited = <Transaction>[];

    for (var i = 0; i < widget.transactions.length; i++) {
      final date = _dateCtrls[i].text.trim();
      final desc = _descCtrls[i].text.trim();
      final amount = double.tryParse(
          _amountCtrls[i].text.replaceAll(',', '.')) ??
          0.0;
      final category = _categoryCtrls[i].text.trim();
      final isIncome = _isIncomeList[i];

      await CategoryInference.addUserMapping(desc, category);

      edited.add(Transaction(
        date: date,
        description: desc,
        amount: amount,
        isIncome: isIncome,
        category: category,
      ));
    }

    try {
      await addAutomaticTransactions(edited);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Success'),
          content:
          Text('${edited.length} transactions saved.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Back to MainWalletScreen; real-time stream ile güncellenir
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => MainWalletScreen()),
                      (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        appBar:
        AppBar(title: const Text('Review & Edit Transactions')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar:
      AppBar(title: const Text('Review & Edit Transactions')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: widget.transactions.length,
        itemBuilder: (context, idx) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _dateCtrls[idx],
                    decoration:
                    const InputDecoration(labelText: 'Date'),
                  ),
                  TextField(
                    controller: _descCtrls[idx],
                    decoration: const InputDecoration(
                        labelText: 'Description'),
                  ),
                  TextField(
                    controller: _amountCtrls[idx],
                    decoration:
                    const InputDecoration(labelText: 'Amount'),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                  ),
                  TextField(
                    controller: _categoryCtrls[idx],
                    decoration: const InputDecoration(
                        labelText: 'Category'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Type:'),
                      const SizedBox(width: 16),
                      DropdownButton<bool>(
                        value: _isIncomeList[idx],
                        items: const [
                          DropdownMenuItem(
                              value: false,
                              child: Text('Expense')),
                          DropdownMenuItem(
                              value: true,
                              child: Text('Income')),
                        ],
                        onChanged: (v) =>
                            setState(() => _isIncomeList[idx] = v!),
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
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ElevatedButton(
            onPressed: _saveAll,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16)),
            child: const Text('Save All'),
          ),
        ),
      ),
    );
  }
}

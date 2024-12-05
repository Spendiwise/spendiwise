import 'package:flutter/material.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction; // Accept a transaction for editing

  AddTransactionScreen({this.transaction}); // Constructor to accept transaction

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String category = 'Food';  // Default category
  bool isIncome = false;  // Default to expense

  @override
  void initState() {
    super.initState();

    // If editing an existing transaction, populate fields with current data
    if (widget.transaction != null) {
      descriptionController.text = widget.transaction!['description'];
      amountController.text = widget.transaction!['amount'].toString();
      category = widget.transaction!['category'];
      isIncome = widget.transaction!['isIncome'];
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
              onPressed: () {
                final description = descriptionController.text;
                final amount = double.tryParse(amountController.text);

                if (description.isNotEmpty && amount != null) {
                  final newTransaction = {
                    'description': description,
                    'amount': amount,
                    'category': category,
                    'isIncome': isIncome,
                    'date': DateTime.now().toString(),
                  };

                  Navigator.pop(context, newTransaction); // Return the new/edited transaction
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

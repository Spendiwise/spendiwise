// lib/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';

class AddTransactionScreen extends StatelessWidget {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final description = descriptionController.text;
                final amount = double.tryParse(amountController.text);

                if (description.isNotEmpty && amount != null) {
                  // Pass the transaction back to the previous screen
                  Navigator.pop(context, {'description': description, 'amount': amount});
                }
              },
              child: Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

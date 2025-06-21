// lib/how_to_upload_screen.dart

import 'package:flutter/material.dart';

class HowToUploadScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("How to Upload File"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "To extract your bank statement correctly, follow these steps:",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text("1. Open your İsBankası app or website."),
            Text("2. Navigate to: Accounts → Account Info → Transactions."),
            Text("3. Select the date range."),
            Text("4. Tap on Download."),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

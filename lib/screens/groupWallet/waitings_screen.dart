import 'package:flutter/material.dart';

class WaitingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final waitings = [
      {'name': 'someone'}, // example of waiting user // TODO: waitings logic
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Waitings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Two columns: First is the name surmane, second is approve (green tick) and decline (red cross)
            Expanded(
              child: ListView.builder(
                itemCount: waitings.length,
                itemBuilder: (context, index) {
                  final w = waitings[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Text(w['name']!,
                            style: TextStyle(fontSize: 16)),
                      ),
                      // Second column: green tick and red cross
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            SizedBox(width: 16),
                            Icon(Icons.close, color: Colors.red),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

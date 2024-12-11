import 'package:flutter/material.dart';

class BalanceSection extends StatelessWidget {
  final double balance;

  BalanceSection({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.green,
      width: double.infinity,
      child: Column(
        children: [
          Text(
            'Your Balance',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

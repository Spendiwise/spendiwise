import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupTransactionList extends StatelessWidget {
  final String groupId; // The group ID to fetch transactions

  GroupTransactionList({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wallets')
          .doc(groupId)
          .collection('transactions') // Fetch transactions for this group
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data!.docs;

        if (transactions.isEmpty) {
          return Center(child: Text("No transactions yet!"));
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return ListTile(
              title: Text(transaction['description']),
              subtitle: Text(transaction['category']),
              trailing: Text(
                (transaction['isIncome'] ? "+ " : "- ") + "\$${transaction['amount']}",
                style: TextStyle(
                  color: transaction['isIncome'] ? Colors.green : Colors.red,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

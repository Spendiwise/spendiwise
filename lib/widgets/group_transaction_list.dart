// lib/widgets/group_transaction_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupTransactionList extends StatelessWidget {
  final String groupId;

  const GroupTransactionList({Key? key, required this.groupId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dynamic balance display
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('wallets')
              .doc(groupId)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return CircularProgressIndicator();
            final data = snap.data!.data() as Map<String, dynamic>?;

            // Cast to double
            double balance = ((data?['balance'] as num?)?.toDouble() ?? 0.0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Balance: \$${balance.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),

        // Transaction list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('wallets')
                .doc(groupId)
                .collection('transactions')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty) return Center(child: Text("No transactions yet!"));

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final tx = docs[i].data() as Map<String, dynamic>;
                  final double amt = (tx['amount'] as num).toDouble();
                  final bool income = tx['isIncome'] as bool;
                  return ListTile(
                    title: Text(tx['description'] as String),
                    subtitle: Text(tx['category'] as String),
                    trailing: Text(
                      '${income ? '+' : '-'} \$${amt.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: income ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

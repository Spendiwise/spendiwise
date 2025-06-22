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
                  final txDoc = docs[i];
                  final tx = txDoc.data() as Map<String, dynamic>;
                  final double amt = (tx['amount'] as num).toDouble();
                  final bool income = tx['isIncome'] as bool;

                  // Extract user_id as DocumentReference or String
                  final userRef = tx['user_id'];

                  // If user_id is stored as String (user email or uid), you need to adjust accordingly
                  // Assuming it's a DocumentReference:
                  return FutureBuilder<DocumentSnapshot>(
                    future: (userRef is DocumentReference) ? userRef.get() : FirebaseFirestore.instance.collection('users').doc(userRef).get(),
                    builder: (context, userSnap) {
                      String userName = 'Unknown User';

                      if (userSnap.hasData && userSnap.data!.exists) {
                        final userData = userSnap.data!.data() as Map<String, dynamic>;
                        userName = userData['name'] ?? userData['email'] ?? 'Unknown User';
                      }

                      return ListTile(
                        title: Text(tx['description'] as String),
                        subtitle: Text('${tx['category'] as String}\nBy: $userName'),
                        trailing: Text(
                          '${income ? '+' : '-'} \$${amt.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: income ? Colors.green : Colors.red,
                          ),
                        ),
                        isThreeLine: true,
                      );
                    },
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

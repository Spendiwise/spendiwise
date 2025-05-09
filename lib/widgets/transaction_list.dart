// lib/widgets/transaction_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'transaction_item.dart';
import '../screens/add_transaction_screen.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('User not logged in'));
    }

    // 1) Base collection reference
    final colRef = FirebaseFirestore.instance
        .collection('transactions')
        .doc(user.uid)
        .collection('transactions');

    // 2) Query with ordering
    final txQuery = colRef.orderBy('date', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: txQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading transactions'));
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text("No transactions yet!"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final tx = doc.data()! as Map<String, dynamic>;
            final txId = doc.id;

            return TransactionItem(
              transaction: tx,
              index: index,
              onEditTransaction: (i, transaction) async {
                // Open the screen for editing, pass document ID
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      transaction: {
                        ...transaction,
                        'id': txId,
                        'date': tx['date'],
                      },
                    ),
                  ),
                );
              },
              onDeleteTransaction: (i) {
                // Delete via the CollectionReference, not Query
                colRef.doc(txId).delete();
              },
            );
          },
        );
      },
    );
  }
}

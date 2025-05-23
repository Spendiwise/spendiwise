// lib/widgets/transaction_list.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/add_transaction_screen.dart';
import 'transaction_item.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('User not logged in'));
    }

    // Collection of this user's transactions
    final colRef = FirebaseFirestore.instance
        .collection('transactions')
        .doc(user.uid)
        .collection('transactions')
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snap, _) => snap.data()!,
      toFirestore: (map, _) => map,
    );

    // Reference to the user's document (for balance updates)
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    // Query ordered by date descending
    final txQuery = colRef.orderBy('date', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
            final tx = doc.data();
            final txId = doc.id;

            return TransactionItem(
              transaction: tx,
              index: index,
              onEditTransaction: (i, transaction) async {
                // 1) Open edit screen, passing the existing transaction and its ID
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      transaction: {
                        ...transaction,
                        'id': txId,
                        'date': transaction['date'],
                      },
                    ),
                  ),
                );

                // 2) After pop, recalculate entire balance from all transactions
                final allTx = await colRef.get();
                double recalculated = allTx.docs.fold(0.0, (sum, d) {
                  final data = d.data();
                  final amt = (data['amount'] as num).toDouble();
                  final isIncome = data['isIncome'] as bool;
                  return sum + (isIncome ? amt : -amt);
                });

                // 3) Update user document with new balance
                await userRef.update({'balance': recalculated});
              },
              onDeleteTransaction: (i) async {
                // 1) Read the transaction to be deleted
                final snapshot = await colRef.doc(txId).get();
                final data = snapshot.data()!;
                final amt = (data['amount'] as num).toDouble();
                final isIncome = data['isIncome'] as bool;

                // 2) Delete the transaction
                await colRef.doc(txId).delete();

                // 3) Fetch current balance
                final userSnap = await userRef.get();
                final oldBal = (userSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;

                // 4) Compute new balance (reverse the deleted tx)
                final newBal = isIncome ? oldBal - amt : oldBal + amt;

                // 5) Update user document
                await userRef.update({'balance': newBal});
              },
            );
          },
        );
      },
    );
  }
}

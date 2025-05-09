// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'text_parser.dart' as my_model;

Future<void> addAutomaticTransactions(
    List<my_model.Transaction> transactions) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not authenticated.');
  }

  final txCol = FirebaseFirestore.instance
      .collection('transactions')
      .doc(user.uid)
      .collection('transactions');

  final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final userSnap = await userRef.get();
  final userData = userSnap.data() as Map<String, dynamic>? ?? {};
  double currentBalance = (userData['balance'] as num?)?.toDouble() ?? 0.0;

  double delta = 0.0;
  for (final txn in transactions) {
    // Parse date string → DateTime
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(txn.date);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    await txCol.add({
      'date': parsedDate,
      'description': txn.description,
      'amount': txn.amount,
      'isIncome': txn.isIncome,
      'category': txn.category,
      'user_id': user.uid,
      'modified_at': FieldValue.serverTimestamp(),
    });

    delta += txn.isIncome ? txn.amount : -txn.amount;
  }

  final newBalance = currentBalance + delta;
  await userRef.update({'balance': newBalance});
}

// firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'text_parser.dart' as my_model;

Future<void> addAutomaticTransactions(
    List<my_model.Transaction> transactions) async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not authenticated.');
  }

  final coll =
  FirebaseFirestore.instance.collection('transactions');

  for (final txn in transactions) {
    await coll.add({
      'date': txn.date,
      'description': txn.description,
      'amount': txn.amount,
      'isIncome': txn.isIncome,
      'category': txn.category,
      'user_id': user.uid,
    });
  }
}

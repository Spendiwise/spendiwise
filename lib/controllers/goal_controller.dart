import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> addGoalToFirestore({
  required String title,
  required double target,
  required String email,
  String? groupId,
  required int goalFlag,
}) async {
  try {
    await FirebaseFirestore.instance.collection('goals').add({
      'title': title,
      'target': target,
      'email': goalFlag == 0 ? email : null,
      'groupId': goalFlag == 1 ? groupId : null,
      'goalFlag': goalFlag,
    });
  } catch (e) {
    if (kDebugMode) {
      print("Error adding goal: $e");
    }
  }
}

Future<void> updateGoal({
  required String goalId,
  required String newTitle,
  required double newTarget,
}) async {
  try {
    await FirebaseFirestore.instance.collection('goals').doc(goalId).update({
      'title': newTitle,
      'target': newTarget,
    });
  } catch (e) {
    if (kDebugMode) {
      print("Error updating goal: $e");
    }
  }
}

Future<void> deleteGoal(String goalId) async {
  try {
    await FirebaseFirestore.instance.collection('goals').doc(goalId).delete();
  } catch (e) {
    if (kDebugMode) {
      print("Error deleting goal: $e");
    }
  }
}

Future<List<Map<String, dynamic>>> fetchGoals({
  required String email,
  String? groupId,
  required int goalFlag,
}) async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('goals')
        .where(goalFlag == 0 ? 'email' : 'groupId', isEqualTo: goalFlag == 0 ? email : groupId)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      'title': doc['title'],
      'target': doc['target'],
    }).toList();
  } catch (e) {
    if (kDebugMode) {
      print("Error fetching goals: $e");
    }
    return [];
  }
}

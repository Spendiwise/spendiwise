import 'package:cloud_firestore/cloud_firestore.dart';

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
    print("Error adding goal: $e");
  }
}

Future<List<Map<String, dynamic>>> fetchGoals({required String email, String? groupId, required int goalFlag}) async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('goals')
        .where(goalFlag == 0 ? 'email' : 'groupId', isEqualTo: goalFlag == 0 ? email : groupId)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      'title': doc['title'],
      'target': doc['target'],
    }).toList();
  } catch (e) {
    print("Error fetching goals: $e");
    return [];
  }
}
List<Map<String, dynamic>> updateGoalsController(List<Map<String, dynamic>> updatedGoals) {
  return List<Map<String, dynamic>>.from(updatedGoals);
}

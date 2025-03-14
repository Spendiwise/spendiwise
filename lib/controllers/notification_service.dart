import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addNotification(String email, String title, String description) async {
    try {
      await _firestore.collection('notification').add({
        'email': email,
        'title': title,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      print("✅ Notification added successfully!");
    } catch (e) {
      print("❌ An error occurred while adding the notification: $e");
    }
  }
}

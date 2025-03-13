import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatelessWidget {
  final String userEmail;

  NotificationsScreen({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notification')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notification')
            .where('email', isEqualTo: userEmail)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var notifications = snapshot.data!.docs;

          return notifications.isEmpty
              ? Center(child: Text('No notifications'))
              : ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notif = notifications[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text(notif['title']),
                  subtitle: Text(
                    '${notif['description']} \nDate: ${notif['timestamp'].toDate()}',
                    style: TextStyle(fontSize: 14),
                  ),
                  isThreeLine: true,
                  trailing: notif['isRead'] == false
                      ? Icon(Icons.circle, color: Colors.blue, size: 12)
                      : null,
                  onTap: () {
                    _markAsRead(notifications[index].id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _markAsRead(String docId) {
    FirebaseFirestore.instance.collection('notification').doc(docId).update({
      'isRead': true,
    });
  }
}

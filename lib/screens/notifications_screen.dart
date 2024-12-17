// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // A mock list of notifications
  List<Map<String, dynamic>> notifications = [
    {
      'title': 'Group Wallet',
      'description': 'Someone sent a request to join your group wallet.',
      'date': DateTime.now().toString(),
    },
    {
      'title': 'Goal Reminder',
      'description': 'You are close to reaching your "Save for Vacation" goal!',
      'date': DateTime.now().subtract(Duration(days:1)).toString(),
    },
    {
      'title': 'Limit Alert',
      'description': 'You are close to exceeding your monthly spending limit.',
      'date': DateTime.now().subtract(Duration(days:2)).toString(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? Center(child: Text('No notifications'))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Card(
            child: ListTile(
              title: Text(notif['title']),
              subtitle: Text(
                '${notif['description']}\nDate: ${notif['date']}',
                style: TextStyle(fontSize: 14),
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    notifications.removeAt(index);
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

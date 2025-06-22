// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Milestone color and icon mappings
const Map<int, Color> milestoneColors = {
  25: Colors.amber,
  50: Colors.deepOrange,
  75: Colors.lightBlue,
  100: Colors.green,
};

const Map<int, IconData> milestoneIcons = {
  25: Icons.flag,
  50: Icons.outlined_flag,
  75: Icons.outlined_flag_rounded,
  100: Icons.celebration,
};

class NotificationsScreen extends StatelessWidget {
  final String userEmail;

  NotificationsScreen({required this.userEmail});

  Future<void> _clearAll(BuildContext context) async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await FirebaseFirestore.instance
        .collection('notification')
        .where('email', isEqualTo: userEmail)
        .get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All notifications cleared')),
    );
  }

  String _formatDate(Timestamp ts) {
    final dt = ts.toDate().toLocal();
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            tooltip: 'Clear All',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Clear all notifications?'),
                  content: Text(
                    'This will remove all notifications permanently.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _clearAll(context);
              }
            },
          ),
        ],
      ),
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
          final notifications = snapshot.data!.docs;
          if (notifications.isEmpty) {
            return Center(child: Text('No notifications'));
          }
          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final notif = doc.data() as Map<String, dynamic>;
              final formattedDate =
              _formatDate(notif['timestamp'] as Timestamp);

              final milestone = notif['milestone'] as int? ?? 0;
              final color = milestoneColors[milestone] ?? Colors.grey;
              final iconData =
                  milestoneIcons[milestone] ?? Icons.notifications;
              final isRead = notif['isRead'] as bool? ?? false;

              // Compute a 20% opacity equivalent alpha value using color.a
              final bgColor = isRead
                  ? Colors.grey.shade100
                  : color.withAlpha((color.alpha * 0.2).round());

              return Container(
                margin: EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(
                    left: BorderSide(
                      color: isRead ? Colors.grey : color,
                      width: 4,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(iconData, color: color),
                  title: Text(
                    notif['title'],
                    style: TextStyle(
                      fontWeight:
                      isRead ? FontWeight.normal : FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif['description'],
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    FirebaseFirestore.instance
                        .collection('notification')
                        .doc(doc.id)
                        .update({'isRead': true});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

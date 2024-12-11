import 'package:flutter/material.dart';
import 'waitings_screen.dart';

class MembersScreen extends StatelessWidget {
  final String groupName;

  MembersScreen({required this.groupName});

  @override
  Widget build(BuildContext context) {
    final members = [
      {'name': 'Name surmame', 'role': 'admin'},
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Members of $groupName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Here is a two-column structure. The first column is the name, the second column is the role.
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Text(member['name']!,
                            style: TextStyle(fontSize: 16)),
                      ),
                      Expanded(
                        child: Text(member['role']!, // TODO: roles and permissions will be added
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height:16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Go to Waitings screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WaitingsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Waitings'),
              ),
            ),
            SizedBox(height:16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showInviteBottomSheet(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteBottomSheet(BuildContext context) {
    final groupCode = 'ABC123'; // group code example TODO: group code logic
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Group Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: groupCode,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Send Invitation'), // TODO: send invitation logic
              ),
            ],
          ),
        );
      },
    );
  }
}

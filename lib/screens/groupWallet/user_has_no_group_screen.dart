// lib/screens/groupWallet/user_has_no_group_screen.dart
import 'package:flutter/material.dart';
import '../../controllers/group_controller.dart';
import 'create_group_wallet_screen.dart';
import 'join_group_screen.dart';

class UserHasNoGroupScreen extends StatelessWidget {
  final Function(String) onGroupCreated;

  UserHasNoGroupScreen({required this.onGroupCreated});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Group Wallet'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'You have no group.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: () async {
                  // Navigate to CreateGroupWalletScreen and wait for result
                  final createdGroupName = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateGroupWalletScreen()),
                  );

                  // If a group name is returned, call onGroupCreated callback
                  if (createdGroupName != null && createdGroupName is String && createdGroupName.trim().isNotEmpty) {
                    onGroupCreated(createdGroupName);
                  }
                },
                child: Text('Create group wallet'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  goToJoinGroupWalletScreen(context);
                },
                child: Text('Join a group wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

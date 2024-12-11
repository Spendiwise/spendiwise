// lib/screens/groupWallet/user_has_no_group_screen.dart

import 'package:flutter/material.dart';
import '../../controllers/group_controller.dart'; // Controller import
import 'create_group_wallet_screen.dart';
import 'join_group_screen.dart';

class UserHasNoGroupScreen extends StatelessWidget {
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
                'You have no group',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  // Call controller function to navigate to create_group_wallet_screen
                  goToCreateGroupWalletScreen(context);
                },
                child: Text('Create group wallet'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Call controller function to navigate to join_group_screen
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

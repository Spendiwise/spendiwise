// lib/screens/groupWallet/create_group_wallet_screen.dart

import 'package:flutter/material.dart';
import 'group_wallet_screen.dart';

class CreateGroupWalletScreen extends StatefulWidget {
  @override
  _CreateGroupWalletScreenState createState() => _CreateGroupWalletScreenState();
}

class _CreateGroupWalletScreenState extends State<CreateGroupWalletScreen> {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupDescriptionController = TextEditingController();

  String? errorMessage; // For showing error if group name is empty

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Group Wallet'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: groupNameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  errorText: errorMessage,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: groupDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Group Description',
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (groupNameController.text.trim().isEmpty) {
            setState(() {
              errorMessage = 'Group name cannot be empty';
            });
          } else {
            // Navigate to GroupWalletScreen with the created group name
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GroupWalletScreen(
                  groupName: groupNameController.text.trim(),

                ),
              ),
            );
          }
        },
        child: Text('Create'),
      ),
    );
  }
}

// lib/screens/groupWallet/create_group_wallet_screen.dart
import 'package:flutter/material.dart';

class CreateGroupWalletScreen extends StatefulWidget {
  @override
  _CreateGroupWalletScreenState createState() => _CreateGroupWalletScreenState();
}

class _CreateGroupWalletScreenState extends State<CreateGroupWalletScreen> {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupDescriptionController = TextEditingController();

  String? errorMessage;

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
            // Return the created group name to the previous screen
            Navigator.pop(context, groupNameController.text.trim());
          }
        },
        child: Text('Create'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateGroupWalletScreen extends StatefulWidget {
  @override
  _CreateGroupWalletScreenState createState() =>
      _CreateGroupWalletScreenState();
}

class _CreateGroupWalletScreenState extends State<CreateGroupWalletScreen> {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupDescriptionController = TextEditingController();

  String? errorMessage;

  // Firebase instances
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Function to create group in Firestore
  Future<void> createGroup(String groupName, String groupDescription) async {
    try {
      // Get the current user's ID
      User? user = auth.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'User not authenticated';
        });
        return;
      }

      // Step 1: Add the group details to the Firestore "wallets" collection
      DocumentReference walletRef = await firestore.collection('wallets').add({
        'name': groupName,
        'description': groupDescription,
        'creation_date': FieldValue.serverTimestamp(),
        'balance': 0,
        'code': 'ABC', // This can be replaced with your logic for code
        'wallet_type': 'group',
      });

      // Step 2: Add the user to the "userWallet" collection
      await firestore.collection('userWallet').add({
        'user_id': user.uid, // Current authenticated user ID
        'wallet_id': walletRef.id, // The newly created wallet's ID
        'role': 'admin', // The user will be the 'admin' by default
      });

      // Success - Navigate back with the group name
      Navigator.pop(context, groupName);
    } catch (e) {
      print('Error creating group: $e');
      setState(() {
        errorMessage = 'Failed to create group. Please try again later.';
      });
    }
  }

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
          String groupName = groupNameController.text.trim();
          String groupDescription = groupDescriptionController.text.trim();

          if (groupName.isEmpty) {
            setState(() {
              errorMessage = 'Group name cannot be empty';
            });
          } else {
            // Call the function to create the group in Firestore
            createGroup(groupName, groupDescription);
          }
        },
        child: Text('Create'),
      ),
    );
  }
}

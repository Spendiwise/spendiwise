import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/random_code_generator.dart';

class CreateGroupWalletScreen extends StatefulWidget {
  @override
  _CreateGroupWalletScreenState createState() => _CreateGroupWalletScreenState();
}

class _CreateGroupWalletScreenState extends State<CreateGroupWalletScreen> {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupDescriptionController = TextEditingController();
  String? errorMessage;

  // Firebase instances
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<String> generateUniqueCode() async {
    String code;
    bool exists;
    do {
      code = RandomCodeGenerator.generateCode();
      var result = await firestore.collection('wallets').where('code', isEqualTo: code).get();
      exists = result.docs.isNotEmpty;
    } while (exists);
    return code;
  }

  Future<void> createGroup(String groupName, String groupDescription) async {
    try {
      User? user = auth.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'User not authenticated';
        });
        return;
      }

      String groupCode = await generateUniqueCode();

      DocumentReference walletRef = await firestore.collection('wallets').add({
        'name': groupName,
        'description': groupDescription,
        'creation_date': FieldValue.serverTimestamp(),
        'balance': 0,
        'code': groupCode,
        'wallet_type': 'group',
      });

      await firestore.collection('userWallet').add({
        'user_id': user.uid,
        'wallet_id': walletRef.id,
        'role': 'admin',
      });

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
            createGroup(groupName, groupDescription);
          }
        },
        child: Text('Create'),
      ),
    );
  }
}

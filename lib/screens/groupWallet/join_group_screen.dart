import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinGroupScreen extends StatefulWidget {
  @override
  _JoinGroupScreenState createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final TextEditingController groupCodeController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  bool isLoading = false;
  String? errorMessage;

  Future<void> joinGroup() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String groupCode = groupCodeController.text.trim();
    User? user = auth.currentUser;

    if (groupCode.isEmpty || user == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Invalid group code or not logged in.';
      });
      return;
    }

    try {
      // Check group code is valid
      var groupQuery = await firestore
          .collection('wallets')
          .where('code', isEqualTo: groupCode)
          .limit(1)
          .get();

      if (groupQuery.docs.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Group not found. Please check the code.';
        });
        return;
      }

      var groupDoc = groupQuery.docs.first;
      var groupId = groupDoc.id;
      var members = List<String>.from(groupDoc['members'] ?? []);
      var userEmail = user.email ?? '';

      if (members.contains(userEmail)) {
        setState(() {
          isLoading = false;
          errorMessage = 'You are already a member of this group.';
        });
        return;
      }

      // Add user `members` array
      members.add(userEmail);
      await firestore.collection('wallets').doc(groupId).update({
        'members': members,
      });

      setState(() {
        isLoading = false;
      });

      Navigator.pop(context, groupDoc['name']);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error joining group: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Group'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: groupCodeController,
                decoration: InputDecoration(
                  labelText: 'Group Code',
                  errorText: errorMessage,
                ),
              ),
              SizedBox(height: 16),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: joinGroup,
                child: Text('Join'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

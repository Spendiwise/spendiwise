import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../screens/main_wallet_screen.dart';

class MembersActions {
  // Function to copy group code to clipboard
  static Future<void> copyGroupCode(String? groupCode, BuildContext context) async {
    if (groupCode != null) {
      await Clipboard.setData(ClipboardData(text: groupCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group Code copied to clipboard!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group Code is not available!')),
      );
    }
  }

  // Function to remove a member from the group
  static Future<void> removeMemberFromGroup({
    required FirebaseFirestore firestore,
    required String groupId,
    required String email,
    required BuildContext context,
    required Function(String) removeMemberCallback,
  }) async {
    DocumentReference groupRef = firestore.collection('wallets').doc(groupId);

    // Remove user email from 'members' list
    await groupRef.update({
      'members': FieldValue.arrayRemove([email]),
    });

    // Get the updated document to check if any members are left
    DocumentSnapshot updatedGroup = await groupRef.get();
    List<dynamic> updatedMembers = updatedGroup['members'] ?? [];

    // If the members list is empty, delete group completely.
    if (updatedMembers.isEmpty) {
      await groupRef.delete();
      if (kDebugMode) {
        print('Group deleted because no members left.');
      }
    }

    // Callback to update UI
    removeMemberCallback(email);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have successfully left the group!')),
    );

    // Redirect user to MainWalletScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainWalletScreen()),
    );
  }

  // Function to update group description
  static Future<void> updateGroupDescription({
    required FirebaseFirestore firestore,
    required String groupId,
    required String newDescription,
    required BuildContext context,
    required Function(String) updateDescriptionCallback,
  }) async {
    if (newDescription.isNotEmpty) {
      await firestore.collection('wallets').doc(groupId).update({
        'description': newDescription,
      });
      updateDescriptionCallback(newDescription);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group description updated successfully!')),
      );
    }
  }

  // Function to invite a user to the group
  static Future<void> inviteUser({
    required FirebaseFirestore firestore,
    required String groupId,
    required BuildContext context,
    required List<String> members,
    required Function(String) addMemberCallback,
  }) async {
    TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invite User'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'User Email',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String invitedEmail = emailController.text.trim();
                if (invitedEmail.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email cannot be empty')),
                  );
                  return;
                }
                // Check if user exists in "users" collection
                QuerySnapshot userSnapshot = await firestore
                    .collection('users')
                    .where('email', isEqualTo: invitedEmail)
                    .get();
                if (userSnapshot.docs.isEmpty) {
                  // User not found
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User with this email does not exist')),
                  );
                } else {
                  // Check if already a member
                  if (members.contains(invitedEmail)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User is already a member')),
                    );
                  } else {
                    // Add the email to the group's members array
                    await firestore.collection('wallets').doc(groupId).update({
                      'members': FieldValue.arrayUnion([invitedEmail]),
                    });
                    addMemberCallback(invitedEmail);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User invited successfully')),
                    );
                  }
                }
                Navigator.pop(context); // Close dialog after operation
              },
              child: const Text('Invite'),
            ),
          ],
        );
      },
    );
  }
}

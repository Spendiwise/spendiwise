import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'personal_wallet_screen.dart';
import 'groupWallet/group_wallet_screen.dart';
import 'groupWallet/user_has_no_group_screen.dart';

class MainWalletScreen extends StatefulWidget {
  @override
  _MainWalletScreenState createState() => _MainWalletScreenState();
}

class _MainWalletScreenState extends State<MainWalletScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool hasGroup = false;
  String groupName = "";

  @override
  void initState() {
    super.initState();
    _checkForGroupWallet();
  }

  Future<void> _checkForGroupWallet() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      String userEmail = user.email ?? '';

      // Fetch wallets where the user is a member
      QuerySnapshot walletsSnapshot = await _firestore
          .collection('wallets')
          .where('members', arrayContains: userEmail)
          .where('wallet_type', isEqualTo: 'group')
          .get();

      if (walletsSnapshot.docs.isNotEmpty) {
        var groupDoc = walletsSnapshot.docs.first;
        setState(() {
          hasGroup = true;
          groupName = groupDoc['name'];
        });
      } else {
        setState(() {
          hasGroup = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget secondPage = hasGroup
        ? GroupWalletScreen(groupName: groupName)
        : UserHasNoGroupScreen(
      onGroupCreated: (String createdGroupName) {
        setState(() {
          hasGroup = true;
          groupName = createdGroupName;
          _addUserToGroupWallet(createdGroupName);
        });

        // After adding user to group, set the PageController to the group wallet screen.
        _pageController.jumpToPage(1); // This ensures the user is taken to the group wallet screen directly after joining.
      },
    );

    return PageView(
      controller: _pageController,
      children: [
        PersonalWalletScreen(),
        secondPage,
      ],
    );
  }

  Future<void> _addUserToGroupWallet(String groupName) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      String uid = user.uid;
      String userEmail = user.email ?? '';

      QuerySnapshot groupWalletSnapshot = await _firestore
          .collection('wallets')
          .where('name', isEqualTo: groupName)
          .where('wallet_type', isEqualTo: 'group')
          .get();

      if (groupWalletSnapshot.docs.isNotEmpty) {
        var groupWalletDoc = groupWalletSnapshot.docs.first;
        String groupId = groupWalletDoc.id;

        await _firestore.collection('userWallet').add({
          'user_id': uid,
          'wallet_id': groupId,
        });

        var members = List<String>.from(groupWalletDoc['members'] ?? []);
        if (!members.contains(userEmail)) {
          members.add(userEmail);
          await _firestore.collection('wallets').doc(groupId).update({
            'members': members,
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }
}

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
    _checkForGroupWallet(); // Check for group wallet on initialization
  }

  Future<void> _checkForGroupWallet() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      String uid = user.uid;

      // Step 1: Get all wallet IDs for the user
      QuerySnapshot userWalletsSnapshot = await _firestore
          .collection('userWallet')
          .where('user_id', isEqualTo: uid)
          .get();

      List<String> walletIds = userWalletsSnapshot.docs
          .map((doc) => doc['wallet_id'] as String)
          .toList();

      if (walletIds.isEmpty) {
        setState(() {
          hasGroup = false; // No wallets associated
        });
        return;
      }

      // Step 2: Check if any wallet has type "group"
      QuerySnapshot walletsSnapshot = await _firestore
          .collection('wallets')
          .where(FieldPath.documentId, whereIn: walletIds)
          .where('wallet_type', isEqualTo: 'group')
          .get();

      if (walletsSnapshot.docs.isNotEmpty) {
        // Group wallet found
        setState(() {
          hasGroup = true;
          groupName = walletsSnapshot.docs.first['name']; // Use the first group's name
        });
      } else {
        setState(() {
          hasGroup = false; // No group wallet
        });
      }
    } catch (e) {
      print("Error checking group wallet: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Decide second page based on hasGroup
    Widget secondPage = hasGroup
        ? GroupWalletScreen(groupName: groupName)
        : UserHasNoGroupScreen(
            onGroupCreated: (String createdGroupName) {
              setState(() {
                hasGroup = true;
                groupName = createdGroupName;
              });
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
}

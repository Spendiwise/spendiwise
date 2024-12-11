// lib/controllers/group_controller.dart

import 'package:flutter/material.dart';
import '../screens/groupWallet/create_group_wallet_screen.dart';
import '../screens/groupWallet/join_group_screen.dart';

// This controller file handles navigation logic and will be extended later if needed

void goToCreateGroupWalletScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => CreateGroupWalletScreen()),
  );
}

void goToJoinGroupWalletScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => JoinGroupScreen()),
  );
}

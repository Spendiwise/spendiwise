// lib/screens/main_wallet_screen.dart
import 'package:flutter/material.dart';
import 'personal_wallet_screen.dart';
import 'groupWallet/user_has_no_group_screen.dart';
import 'groupWallet/group_wallet_screen.dart';

class MainWalletScreen extends StatefulWidget {
  @override
  _MainWalletScreenState createState() => _MainWalletScreenState();
}

class _MainWalletScreenState extends State<MainWalletScreen> {
  final PageController _pageController = PageController(initialPage: 0);

  bool hasGroup = false;  // TODO: It should work according to database

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      children: [
        PersonalWalletScreen(),
        hasGroup
            ? GroupWalletScreen(groupName: 'My Group') // TODO: This is also about database
            : UserHasNoGroupScreen(),
      ],
    );
  }
}

// lib/screens/main_wallet_screen.dart
import 'package:flutter/material.dart';
import 'personal_wallet_screen.dart';
import 'groupWallet/group_wallet_screen.dart';
import 'groupWallet/user_has_no_group_screen.dart';

//Here, the screens that will appear as a result of swiping left and right are managed.

class MainWalletScreen extends StatefulWidget {
  @override
  _MainWalletScreenState createState() => _MainWalletScreenState();
}

class _MainWalletScreenState extends State<MainWalletScreen> {
  final PageController _pageController = PageController(initialPage: 0);

  bool hasGroup = false;
  String groupName = "";

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

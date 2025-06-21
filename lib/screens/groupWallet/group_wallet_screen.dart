// lib/screens/group_wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Controllers
import '../../controllers/goal_controller.dart';

// Widgets
import '../../widgets/balance_section.dart';
import '../../widgets/goals_button.dart';
import '../../widgets/search_transaction_button.dart';
import '../../widgets/group_transaction_list.dart';
import '../../widgets/automatic_transaction_button.dart';

// Screens
import 'members_screen.dart';
import 'create_group_wallet_screen.dart';
import 'join_group_screen.dart';
import '../../screens/add_transaction_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/forecasting_screen.dart';

class GroupWalletScreen extends StatefulWidget {
  final String groupName;

  GroupWalletScreen({required this.groupName});

  @override
  _GroupWalletScreenState createState() => _GroupWalletScreenState();
}

class _GroupWalletScreenState extends State<GroupWalletScreen>
    with AutomaticKeepAliveClientMixin {
  String currentGroupName = '';
  String? groupId;
  List<String> userGroups = [];
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final String userEmail =
      FirebaseAuth.instance.currentUser?.email ?? 'unknown@example.com';

  @override
  void initState() {
    super.initState();
    currentGroupName = widget.groupName;
    _fetchGroupId();
    _fetchUserGroups();
  }

  Future<void> _fetchUserGroups() async {
    final email = _auth.currentUser?.email;
    if (email == null) return;

    final qs = await _firestore
        .collection('wallets')
        .where('members', arrayContains: email)
        .get();

    setState(() {
      userGroups = qs.docs.map((d) => d['name'] as String).toList();
    });
  }

  Future<void> _fetchGroupId() async {
    final qs = await _firestore
        .collection('wallets')
        .where('name', isEqualTo: currentGroupName)
        .limit(1)
        .get();

    if (qs.docs.isNotEmpty) {
      setState(() {
        groupId = qs.docs.first.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.group),
          onPressed: () {
            if (groupId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MembersScreen(
                    groupId: groupId!,
                    groupName: currentGroupName,
                    email: userEmail,
                  ),
                ),
              );
            }
          },
        ),
        centerTitle: true,
        title: PopupMenuButton<String>(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(currentGroupName),
              SizedBox(width: 4),
              Icon(Icons.arrow_drop_down),
            ],
          ),
          onSelected: (value) {
            if (value == 'join') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JoinGroupScreen()),
              ).then((_) => _fetchUserGroups());
            } else if (value == 'create') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateGroupWalletScreen()),
              ).then((newName) {
                if (newName != null) {
                  setState(() => currentGroupName = newName);
                  _fetchUserGroups();
                  _fetchGroupId();
                }
              });
            } else {
              setState(() => currentGroupName = value);
              _fetchGroupId();
            }
          },
          itemBuilder: (_) {
            final items = <PopupMenuEntry<String>>[];
            if (userGroups.isNotEmpty) {
              items.addAll(userGroups.map((g) => PopupMenuItem(
                value: g,
                child: Text(g),
              )));
              items.add(PopupMenuDivider());
            }
            items.add(PopupMenuItem(value: 'join', child: Text('Join a group')));
            items.add(PopupMenuItem(value: 'create', child: Text('Create group')));
            return items;
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationsScreen(userEmail: user.email!),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.cloud),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ForecastingScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (groupId != null)
            StreamBuilder<DocumentSnapshot>(
              stream:
              _firestore.collection('wallets').doc(groupId!).snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                );
                final data = snap.data!.data() as Map<String, dynamic>?;
                final bal = (data?['balance'] as num?)?.toDouble() ?? 0.0;
                return BalanceSection(balance: bal);
              },
            ),

          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GoalsButton(
                  balance: 0,
                  email: userEmail,
                  groupId: groupId,
                  goalFlag: 1,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SearchTransactionButton(),
              ),
            ],
          ),

          SizedBox(height: 16),
          AutomaticTransactionButton(),
          SizedBox(height: 8),

          if (groupId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          Expanded(
            child: groupId != null
                ? GroupTransactionList(groupId: groupId!)
                : Center(child: Text("Select or create a group")),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (groupId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransactionScreen(groupId: groupId),
              ),
            );
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

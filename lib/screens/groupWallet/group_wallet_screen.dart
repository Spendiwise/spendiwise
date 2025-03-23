import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tryout/widgets/forecasting_button.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/goal_controller.dart';
import '../../widgets/balance_section.dart';
import '../../widgets/goals_button.dart';
import '../../widgets/search_transaction_button.dart';
import '../../widgets/transaction_list.dart';
import '../../widgets/add_transaction_fab.dart';
import 'members_screen.dart';
import '../../screens/events_subscription_screen.dart';
import '../../widgets/events_button.dart';
import 'create_group_wallet_screen.dart';
import 'join_group_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/add_transaction_screen.dart';
import '../../widgets/group_transaction_list.dart';
import '../../widgets/automatic_transaction_button.dart';

class GroupWalletScreen extends StatefulWidget {
  final String groupName;

  GroupWalletScreen({required this.groupName});

  @override
  _GroupWalletScreenState createState() => _GroupWalletScreenState();
}

class _GroupWalletScreenState extends State<GroupWalletScreen> {
  double balance = 0.0;
  String? groupId;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> goals = [];
  List<String> userGroups = [];

  late String currentGroupName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String? userEmail = FirebaseAuth.instance.currentUser?.email ?? "unknown@example.com";

  @override
  void initState() {
    super.initState();
    currentGroupName = widget.groupName;
    _fetchGroupData();
    _fetchUserGroups(); //We pull the groups the user is a member of.
  }

  Future<void> _fetchGroupData() async {
    var groupQuery = await firestore
        .collection('wallets')
        .where('name', isEqualTo: currentGroupName)
        .limit(1)
        .get();

    if (groupQuery.docs.isNotEmpty) {
      var groupDoc = groupQuery.docs.first;
      setState(() {
        groupId = groupDoc.id;
        balance = (groupDoc['balance'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _fetchUserGroups() async {
    // Query to fetch groups where the user's email exists in the "members" array
    QuerySnapshot querySnapshot = await firestore
        .collection('wallets')
        .where('members', arrayContains: userEmail)
        .get();
    List<String> groups = [];
    for (var doc in querySnapshot.docs) {
      groups.add(doc['name']);
    }
    setState(() {
      userGroups = groups;
    });
  }

  Future<void> _updateGroupBalance(double newBalance) async {
    if (groupId == null) return;
    await firestore.collection('wallets').doc(groupId).update({'balance': newBalance});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.group),
          onPressed: () {
            if (groupId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MembersScreen(
                    groupId: groupId!,
                    groupName: currentGroupName,
                    email: userEmail ?? "unknown@example.com",
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
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
          onSelected: (value) {
            if (value == 'create') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateGroupWalletScreen(),
                ),
              ).then((createdGroupName) {
                if (createdGroupName != null) {
                  setState(() {
                    currentGroupName = createdGroupName;
                  });
                  _fetchUserGroups(); // Refresh groups after new group creation
                }
              });
            } else if (value == 'join') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JoinGroupScreen(),
                ),
              ).then((_) {
                _fetchUserGroups(); // Refresh groups after joining the group
              });
            } else {
              // User selects existing group
              setState(() {
                currentGroupName = value;
              });
              _fetchGroupData(); // Retrieve data of selected group
            }
          },
          itemBuilder: (context) {
            List<PopupMenuEntry<String>> items = [];
            // Add groups the user is a member of
            if (userGroups.isNotEmpty) {
              items.addAll(
                userGroups.map((group) => PopupMenuItem<String>(
                  value: group,
                  child: Text(group),
                )),
              );
              items.add(const PopupMenuDivider());
            }
            // Join a group wallet option
            items.add(
              const PopupMenuItem<String>(
                value: 'join',
                child: Text('Join a group wallet'),
              ),
            );
            // Create a group wallet option
            items.add(
              const PopupMenuItem<String>(
                value: 'create',
                child: Text('Create a group wallet'),
              ),
            );
            return items;
          },
        ),
      ),
      body: Column(
        children: [
          BalanceSection(balance: balance),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GoalsButton(
                  balance: balance,
                  email: userEmail ?? "unknown@example.com",
                  groupId: groupId,
                  goalFlag: 1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SearchTransactionButton(
                  transactions: transactions,
                  onTransactionsUpdated: (updatedTransactions, updatedBalance) {
                    setState(() {
                      transactions = updatedTransactions;
                      balance = updatedBalance;
                      _updateGroupBalance(balance);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Automatic Transaction Button
          AutomaticTransactionButton(),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
          if (transactions.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Transaction History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: groupId != null
                ? GroupTransactionList(groupId: groupId!)
                : Center(child: Text("Select a group wallet")),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(groupId: groupId),
            ),
          ).then((_) {
            _fetchGroupData(); // Refresh group balance after returning
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

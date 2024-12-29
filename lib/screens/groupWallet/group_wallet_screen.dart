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
import 'create_group_wallet_screen.dart'; // Import CreateGroupWalletScreen
import 'join_group_screen.dart'; // Import JoinGroupScreen

class GroupWalletScreen extends StatefulWidget {
  final String groupName;

  GroupWalletScreen({required this.groupName});

  @override
  _GroupWalletScreenState createState() => _GroupWalletScreenState();
}

class _GroupWalletScreenState extends State<GroupWalletScreen> with AutomaticKeepAliveClientMixin {
  double balance = 0.0;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> goals = [];
  List<String> userGroups = []; // No other group

  late String currentGroupName;

  // Firestore instance
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    currentGroupName = widget.groupName;
    _fetchGroupBalance(); // Fetch balance when the screen is initialized
  }

  // Fetch group balance from Firestore
  Future<void> _fetchGroupBalance() async {
    try {
      var groupDoc = await firestore.collection('wallets').where('name', isEqualTo: currentGroupName).limit(1).get();

      if (groupDoc.docs.isNotEmpty) {
        var groupData = groupDoc.docs.first.data();
        setState(() {
          balance = groupData['balance'] ?? 0.0;
        });
      }
    } catch (e) {
      print('Error fetching group balance: $e');
    }
  }

  // Update group balance in Firestore
  Future<void> _updateGroupBalance(double newBalance) async {
    try {
      var groupDoc = await firestore.collection('wallets').where('name', isEqualTo: currentGroupName).limit(1).get();

      if (groupDoc.docs.isNotEmpty) {
        var groupRef = groupDoc.docs.first.reference;
        await groupRef.update({
          'balance': newBalance,
        });
      }
    } catch (e) {
      print('Error updating group balance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.group),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MembersScreen(groupName: currentGroupName),
              ),
            );
          },
        ),
        centerTitle: true,
        title: PopupMenuButton<String>(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(currentGroupName),
              SizedBox(width: 8),
              Icon(Icons.arrow_drop_down),
            ],
          ),
          onSelected: (value) {
            if (value == 'create') {
              // Navigate to Create Group Wallet Screen
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
                }
              });
            } else if (value == 'join') {
              // Navigate to Join Group Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JoinGroupScreen(),
                ),
              );
            } else {
              setState(() {
                currentGroupName = value;
              });
            }
          },
          itemBuilder: (context) {
            if (userGroups.isEmpty) {
              return [
                PopupMenuItem(
                  value: 'create',
                  child: Text('Create group wallet'),
                ),
                PopupMenuItem(
                  value: 'join',
                  child: Text('Join group wallet'),
                ),
              ];
            } else {
              return [
                ...userGroups.map((g) => PopupMenuItem(
                  value: g,
                  child: Text(g),
                )),
                PopupMenuItem(
                  value: 'create',
                  child: Text('Create group wallet'),
                ),
                PopupMenuItem(
                  value: 'join',
                  child: Text('Join group wallet'),
                ),
              ];
            }
          },
        ),
      ),
      body: Column(
        children: [
          BalanceSection(balance: balance),
          SizedBox(height: 16),

          // First row for buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GoalsButton(
                  onGoalsUpdated: (updatedGoals) {
                    setState(() {
                      goals = updateGoalsController(updatedGoals);
                    });
                  },
                  goals: goals,
                  balance: balance,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SearchTransactionButton(
                  transactions: transactions,
                  onTransactionsUpdated: (updatedTransactions, updatedBalance) {
                    setState(() {
                      transactions = updatedTransactions;
                      balance = updatedBalance;
                      _updateGroupBalance(balance); // Update balance after transaction
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Second row for buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ForecastingButton(),
              ),
            ],
          ),

          SizedBox(height: 16),
          if (transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          Expanded(
            child: TransactionList(
              transactions: transactions,
              balance: balance,
              onDeleteTransaction: (index) {
                final result = deleteTransactionController(transactions, balance, index);
                setState(() {
                  transactions = result.updatedTransactions;
                  balance = result.updatedBalance;
                  _updateGroupBalance(balance); // Update balance after deleting transaction
                });
              },
              onEditTransaction: (index, transaction) async {
                final result = await editTransactionController(context, transactions, balance, index);
                if (result != null) {
                  setState(() {
                    transactions = result.updatedTransactions;
                    balance = result.updatedBalance;
                    _updateGroupBalance(balance); // Update balance after editing transaction
                  });
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AddTransactionFAB(
        onTransactionAdded: (newTransaction) {
          final result = addTransactionController(transactions, balance, newTransaction);
          setState(() {
            transactions = result.updatedTransactions;
            balance = result.updatedBalance;
            _updateGroupBalance(balance); // Update balance after adding transaction
          });
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // This keeps the state alive
}

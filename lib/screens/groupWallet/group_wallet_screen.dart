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

  @override
  void initState() {
    super.initState();
    currentGroupName = widget.groupName;
    _fetchGroupData();
  }

  Future<void> _fetchGroupData() async {
    try {
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
    } catch (e) {
      print('Error fetching group data: $e');
    }
  }

  Future<void> _updateGroupBalance(double newBalance) async {
    if (groupId == null) return;

    try {
      await firestore.collection('wallets').doc(groupId).update({'balance': newBalance});
    } catch (e) {
      print('Error updating group balance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.group),
          onPressed: () {
            if (groupId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MembersScreen(groupId: groupId!, groupName: currentGroupName),
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
              SizedBox(width: 8),
              Icon(Icons.arrow_drop_down),
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
                }
              });
            } else if (value == 'join') {
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
                PopupMenuItem(value: 'create', child: Text('Create group wallet')),
                PopupMenuItem(value: 'join', child: Text('Join group wallet')),
              ];
            } else {
              return [
                ...userGroups.map((g) => PopupMenuItem(value: g, child: Text(g))),
                PopupMenuItem(value: 'create', child: Text('Create group wallet')),
                PopupMenuItem(value: 'join', child: Text('Join group wallet')),
              ];
            }
          },
        ),
      ),
      body: Column(
        children: [
          BalanceSection(balance: balance),
          SizedBox(height: 16),
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
                      _updateGroupBalance(balance);
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Expanded(child: ForecastingButton())],
          ),
          SizedBox(height: 16),
          if (transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Transaction History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  _updateGroupBalance(balance);
                });
              },
              onEditTransaction: (index, transaction) async {
                final result = await editTransactionController(context, transactions, balance, index);
                if (result != null) {
                  setState(() {
                    transactions = result.updatedTransactions;
                    balance = result.updatedBalance;
                    _updateGroupBalance(balance);
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
            _updateGroupBalance(balance);
          });
        },
      ),
    );
  }
}

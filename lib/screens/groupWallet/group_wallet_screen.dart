// lib/screens/groupWallet/group_wallet_screen.dart
import 'package:flutter/material.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/group_controller.dart';
import '../../widgets/balance_section.dart';
import '../../widgets/goals_button.dart';
import '../../widgets/search_transaction_button.dart';
import '../../widgets/transaction_list.dart';
import '../../widgets/add_transaction_fab.dart';
import 'members_screen.dart';

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

  @override
  void initState() {
    super.initState();
    currentGroupName = widget.groupName;
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
              goToCreateGroupWalletScreen(context);
            } else if (value == 'join') {
              goToJoinGroupWalletScreen(context);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GoalsButton(
                  balance: balance,
                  goals: goals,
                  onGoalsUpdated: (updatedGoals) {
                    setState(() {
                      goals = updatedGoals;
                    });
                  },
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
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(child: SizedBox()),
            ],
          ),
          SizedBox(height:16),
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
                });
              },
              onEditTransaction: (index, transaction) async {
                final result = await editTransactionController(context, transactions, balance, index);
                if (result != null) {
                  setState(() {
                    transactions = result.updatedTransactions;
                    balance = result.updatedBalance;
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
          });
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // This keeps the state alive
}

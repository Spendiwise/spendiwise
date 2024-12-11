import 'package:flutter/material.dart';
import 'add_transaction_screen.dart';
import 'goal_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double balance = 1500.50;
  List<Map<String, dynamic>> transactions = []; // Store transactions here
  List<Map<String, dynamic>> goals = [
    {'title': 'Save for Vacation', 'target': 5000.0, 'progress': 2000.0},
    {'title': 'Buy a New Laptop', 'target': 1500.0, 'progress': 500.0},
  ];

  // Function to delete a transaction
  void deleteTransaction(int index) {
    setState(() {
      final transaction = transactions[index];
      if (transaction['isIncome']) {
        balance -= transaction['amount'];
      } else {
        balance += transaction['amount'];
      }
      transactions.removeAt(index);
    });
  }

  // Function to edit a transaction
  void editTransaction(int index, Map<String, dynamic> editedTransaction) async {
    final updatedTransaction = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddTransactionScreen(transaction: transactions[index]),
      ),
    );

    if (updatedTransaction != null) {
      setState(() {
        // Update the transaction at the correct index
        transactions[index] = updatedTransaction;

        // Recalculate the balance
        balance = transactions.fold(
          0.0,
          (sum, t) => sum + (t['isIncome'] ? t['amount'] : -t['amount']),
        );
      });
    }
  }

  // Function to update goals (called when returning from GoalScreen)
  void updateGoals(List<Map<String, dynamic>> updatedGoals) {
    setState(() {
      goals = updatedGoals;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Personal Wallet'),
      ),
      body: Column(
        children: [
          // Balance section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.green,
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  'Your Balance',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  '\$${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),
          // Row for buttons placed horizontally
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Navigate to GoalScreen and wait for updated goals
                      final updatedGoals = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GoalScreen(
                            balance: balance, // Pass current balance
                            goals: List<Map<String, dynamic>>.from(goals), // Pass a copy of goals
                          ),
                        ),
                      );

                      // If goals are updated, replace the current list
                      if (updatedGoals != null) {
                        updateGoals(updatedGoals);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),

                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag),
                        SizedBox(height: 8),
                        Text('Goals'),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8), // Small spacing between buttons
              Expanded(
                child: SizedBox(
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () {
                      // Show transaction search
                      showSearch(
                        context: context,
                        delegate: TransactionSearchDelegate(
                          transactions,
                          onEditTransaction: (originalIndex, updatedTransaction) {
                            setState(() {
                              // Update the transaction in the original list
                              transactions[originalIndex] = updatedTransaction;

                              // Recalculate the balance
                              balance = transactions.fold(
                                0.0,
                                    (sum, t) =>
                                sum + (t['isIncome'] ? t['amount'] : -t['amount']),
                              );
                            });
                          },
                          onDeleteTransaction: (originalIndex) {
                            setState(() {
                              // Remove the transaction and adjust the balance
                              final transaction = transactions[originalIndex];
                              if (transaction['isIncome']) {
                                balance -= transaction['amount'];
                              } else {
                                balance += transaction['amount'];
                              }
                              transactions.removeAt(originalIndex);
                            });
                          },
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search),
                        SizedBox(height: 8),
                        Text('Search Transaction'),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),

              //TODO: This space will be used to add the 3rd button

            ],
          ),

          SizedBox(height:16),
          // Added a heading for transaction history
          // This will display above the transactions list
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


          // Transactions list
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                // Use reversed index to show the last added transaction on top
                final reversedIndex = transactions.length - 1 - index;
                final transaction = transactions[reversedIndex];

                // Determine the color based on income or expense
                final lineColor = transaction['isIncome'] ? Colors.green : Colors.red;

                return Card(
                  child: Row(
                    children: [
                      // Colored line on the left side
                      Container(
                        width: 5,
                        height: 100,
                        color: lineColor,
                      ),
                      Expanded(
                        child: ListTile(
                          title: Text(transaction['description']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Amount: \$${transaction['amount'].toStringAsFixed(2)}'),
                              Text('Category: ${transaction['category']}'),
                              Text('Date: ${transaction['date']}'),
                              Text('Type: ${transaction['isIncome'] ? 'Income' : 'Expense'}'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                editTransaction(reversedIndex, transaction); // Edit transaction
                              } else if (value == 'delete') {
                                deleteTransaction(reversedIndex); // Delete transaction
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.large(
        onPressed: () async {
          // Navigate to AddTransactionScreen and wait for the result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransactionScreen()),
          );

          // Add the transaction to the list and update the balance
          if (result != null) {
            setState(() {
              transactions.add(result);
              // Adjust the balance based on whether it’s income or expense
              if (result['isIncome']) {
                balance += result['amount']; // Add income
              } else {
                balance -= result['amount']; // Subtract expense
              }
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class TransactionSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> transactions;
  final Function(int originalIndex, Map<String, dynamic> updatedTransaction)
      onEditTransaction;
  final Function(int originalIndex) onDeleteTransaction;

  TransactionSearchDelegate(
    this.transactions, {
    required this.onEditTransaction,
    required this.onDeleteTransaction,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = ''; // Clear the search query
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Close the search
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = transactions
        .asMap()
        .entries
        .where((entry) {
      final transaction = entry.value;
      return transaction['description']
          .toLowerCase()
          .contains(query.toLowerCase()) ||
          transaction['category']
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          transaction['amount']
              .toString()
              .contains(query) ||
          transaction['date']
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          (transaction['isIncome'] ? 'income' : 'expense')
              .toLowerCase()
              .contains(query.toLowerCase());
    })
        .toList();

    // reverse the results order
    final reversedResults = results.reversed.toList();

    return ListView.builder(
      itemCount: reversedResults.length,
      itemBuilder: (context, index) {
        final originalIndex = reversedResults[index].key;
        final transaction = reversedResults[index].value;

        // Determine the color based on income or expense
        final lineColor = transaction['isIncome'] ? Colors.green : Colors.red;

        return Row(
          children: [
            // Colored line on the left side for search results
            Container(
              width: 5,
              height: 100,
              color: lineColor,
            ),
            Expanded(
              child: ListTile(
                title: Text(transaction['description']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: \$${transaction['amount'].toStringAsFixed(2)}'),
                    Text('Category: ${transaction['category']}'),
                    Text('Date: ${transaction['date']}'),
                    Text('Type: ${transaction['isIncome'] ? 'Income' : 'Expense'}'),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final updatedTransaction = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionScreen(
                            transaction: transaction,
                          ),
                        ),
                      );

                      if (updatedTransaction != null) {
                        onEditTransaction(originalIndex, updatedTransaction);
                      }
                    } else if (value == 'delete') {
                      onDeleteTransaction(originalIndex);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context); // Reuse buildResults logic for suggestions
  }
}

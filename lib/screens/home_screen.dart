import 'package:flutter/material.dart';
import 'add_transaction_screen.dart';
import 'goal_screen.dart'; // Import the Goal Page

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double balance = 1500.50;
  List<Map<String, dynamic>> transactions = []; // Store transactions here
  String searchQuery = ''; // For search filter

  // Function to delete a transaction
  void deleteTransaction(int index) {
    setState(() {
      if (transactions[index]['isIncome']) {
        balance -= transactions[index]['amount'];
      } else {
        balance += transactions[index]['amount'];
      }
      transactions.removeAt(index);
    });
  }

  // Function to edit a transaction
  void editTransaction(Map<String, dynamic> editedTransaction) async {
    final updatedTransaction = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: editedTransaction),
      ),
    );

    if (updatedTransaction != null) {
      setState(() {
        // Find the index of the transaction that was edited
        final index = transactions.indexWhere((t) => t['date'] == editedTransaction['date']);
        if (index != -1) {
          transactions[index] = updatedTransaction;
          // Update balance accordingly
          balance = transactions.fold(0, (sum, item) => sum + item['amount']);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spendiwise'),
        actions: [
          IconButton(
            icon: Icon(Icons.flag),
            tooltip: 'Manage Goals',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GoalScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            tooltip: 'Search Transactions',
            onPressed: () {
              showSearch(
                context: context,
                delegate: TransactionSearchDelegate(
                  transactions,
                  onEditTransaction: editTransaction,
                  onDeleteTransaction: deleteTransaction,
                ),
              );
            },
          ),
        ],
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
          // Transactions list
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Card(
                  child: ListTile(
                    title: Text(transaction['description']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount: \$${transaction['amount'].toStringAsFixed(2)}'),
                        Text('Category: ${transaction['category']}'),
                        Text('Date: ${transaction['date']}'),
                        Text('Type: ${transaction['isIncome'] ? 'Expense' : 'Income'}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          // Edit Transaction
                          editTransaction(transaction); // Pass transaction to edit
                        } else if (value == 'delete') {
                          // Delete Transaction
                          deleteTransaction(index); // Delete the transaction
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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

// Search functionality for transactions
class TransactionSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> transactions;
  final Function(Map<String, dynamic> editedTransaction) onEditTransaction;
  final Function(int index) onDeleteTransaction;

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
          query = ''; // Clear search query
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = transactions.where((transaction) {
      // Checking all aspects of the transaction for the search query
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
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final transaction = results[index];
        return ListTile(
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
                // Edit transaction
                onEditTransaction(transaction);
              } else if (value == 'delete') {
                // Delete transaction
                onDeleteTransaction(index);
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
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = transactions.where((transaction) {
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
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final transaction = suggestions[index];
        return ListTile(
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
                // Edit transaction
                onEditTransaction(transaction);
              } else if (value == 'delete') {
                // Delete transaction
                onDeleteTransaction(index);
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
        );
      },
    );
  }
}

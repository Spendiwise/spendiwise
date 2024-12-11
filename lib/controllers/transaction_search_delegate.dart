import 'package:flutter/material.dart';

typedef EditTransactionCallback = void Function(int originalIndex, Map<String, dynamic> updatedTransaction);
typedef DeleteTransactionCallback = void Function(int originalIndex);

class TransactionSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> transactions;
  final EditTransactionCallback onEditTransaction;
  final DeleteTransactionCallback onDeleteTransaction;
  final Function(BuildContext, Map<String, dynamic>) onNavigateToEditScreen;

  TransactionSearchDelegate(
      this.transactions, {
        required this.onEditTransaction,
        required this.onDeleteTransaction,
        required this.onNavigateToEditScreen,
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
                      await onNavigateToEditScreen(context, transaction);
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

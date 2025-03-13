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
              .toDate()
              .toString()
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

        // Format the date
        final timestamp = transaction['date']; // Assuming Firestore Timestamp
        final DateTime dateTime = timestamp.toDate();
        final String formattedDate = "${dateTime.day}/${dateTime
            .month}/${dateTime.year}";

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Row(
            children: [
              // Colored line indicator
              Container(
                width: 8,
                height: 100,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction description
                      Text(
                        transaction['description'],
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        // Truncate if text is too long
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      // Transaction details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Amount and type
                          Text(
                            'Amount: \$${transaction['amount'].toStringAsFixed(
                                2)}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54),
                          ),
                          Text(
                            transaction['isIncome'] ? 'Income' : 'Expense',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: transaction['isIncome']
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Category and date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Use flexible text
                          Flexible(
                            child: Text(
                              'Category: ${transaction['category']}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black45),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Popup menu actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEditTransaction(index, transaction);
                  } else if (value == 'delete') {
                    onDeleteTransaction(index);
                  }
                },
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) =>
                [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: const [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: const [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

    @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context); // Reuse buildResults logic for suggestions
  }
}

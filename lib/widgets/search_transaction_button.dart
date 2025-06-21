import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchTransactionButton extends StatelessWidget {
  SearchTransactionButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          showSearch(
            context: context,
            delegate: FirebaseTransactionSearchDelegate(),
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
    );
  }
}

class FirebaseTransactionSearchDelegate extends SearchDelegate<String> {
  String _filterType = 'All'; // All, Income, Expense
  String _dateFilter = 'All Time'; // All Time, Last Week, Last Month, Last 3 Months
  String _sortBy = 'Date (Newest)'; // Date (Newest), Date (Oldest), Amount (High), Amount (Low)

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      PopupMenuButton<String>(
        icon: Icon(Icons.filter_list),
        onSelected: (value) {
          if (value.startsWith('filter_')) {
            _filterType = value.replaceFirst('filter_', '');
          } else if (value.startsWith('date_')) {
            _dateFilter = value.replaceFirst('date_', '');
          } else if (value.startsWith('sort_')) {
            _sortBy = value.replaceFirst('sort_', '');
          }
          // Force refresh both suggestions and results
          showSuggestions(context);
          showResults(context);
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'filter_All',
            child: Row(
              children: [
                Icon(_filterType == 'All' ? Icons.check : Icons.radio_button_unchecked),
                SizedBox(width: 8),
                Text('All Transactions'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'filter_Income',
            child: Row(
              children: [
                Icon(_filterType == 'Income' ? Icons.check : Icons.radio_button_unchecked),
                SizedBox(width: 8),
                Text('Income Only'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'filter_Expense',
            child: Row(
              children: [
                Icon(_filterType == 'Expense' ? Icons.check : Icons.radio_button_unchecked),
                SizedBox(width: 8),
                Text('Expenses Only'),
              ],
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem(
            value: 'date_All Time',
            child: Row(
              children: [
                Icon(_dateFilter == 'All Time' ? Icons.check : Icons.radio_button_unchecked),
                SizedBox(width: 8),
                Text('All Time'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'date_Last Week',
            child: Row(
              children: [
                Icon(_dateFilter == 'Last Week' ? Icons.check : Icons.radio_button_unchecked),
                SizedBox(width: 8),
                Text('Last Week'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'date_Last Month',
            child: Row(
              children: [
                Icon(_dateFilter == 'Last Month' ? Icons.check : Icons.radio_button_unchecked),
                SizedBox(width: 8),
                Text('Last Month'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'date_Last 3 Months',
            child: Row(
              children: [
                Icon(_dateFilter == 'Last 3 Months' ? Icons.check : Icons.radio_button_unchecked),
                SizedBox(width: 8),
                Text('Last 3 Months'),
              ],
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem(
            value: 'sort_Date (Newest)',
            child: Row(
              children: [
                Icon(_sortBy == 'Date (Newest)' ? Icons.check : Icons.radio_button_unchecked),
                SizedBox(width: 8),
                Text('Date (Newest)'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'sort_Date (Oldest)',
            child: Row(
              children: [
                Icon(_sortBy == 'Date (Oldest)' ? Icons.check : Icons.radio_button_unchecked),
                SizedBox(width: 8),
                Text('Date (Oldest)'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'sort_Amount (High)',
            child: Row(
              children: [
                Icon(_sortBy == 'Amount (High)' ? Icons.check : Icons.radio_button_unchecked),
                SizedBox(width: 8),
                Text('Amount (High)'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'sort_Amount (Low)',
            child: Row(
              children: [
                Icon(_sortBy == 'Amount (Low)' ? Icons.check : Icons.radio_button_unchecked),
                SizedBox(width: 8),
                Text('Amount (Low)'),
              ],
            ),
          ),
        ],
      ),
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, '');
      },
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';

    DateTime date;
    if (dateValue is Timestamp) {
      date = dateValue.toDate();
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else if (dateValue is String) {
      try {
        date = DateTime.parse(dateValue);
      } catch (e) {
        return dateValue;
      }
    } else {
      return dateValue.toString();
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  bool _matchesDateFilter(dynamic dateValue) {
    if (_dateFilter == 'All Time') return true;
    if (dateValue == null) return false;

    DateTime date;
    if (dateValue is Timestamp) {
      date = dateValue.toDate();
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else if (dateValue is String) {
      try {
        date = DateTime.parse(dateValue);
      } catch (e) {
        return false;
      }
    } else {
      return false;
    }

    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    switch (_dateFilter) {
      case 'Last Week':
        return diff <= 7;
      case 'Last Month':
        return diff <= 30;
      case 'Last 3 Months':
        return diff <= 90;
      default:
        return true;
    }
  }

  Widget _buildSearchResults() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('User not logged in'));
    }

    final colRef = FirebaseFirestore.instance
        .collection('transactions')
        .doc(user.uid)
        .collection('transactions')
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snap, _) => snap.data()!,
      toFirestore: (map, _) => map,
    );

    final txQuery = colRef.orderBy('date', descending: true);

    return Column(
      children: [
        // Active filters display
        Container(
          padding: EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            children: [
              if (_filterType != 'All')
                Chip(
                  label: Text(_filterType),
                  backgroundColor: Colors.blue.shade100,
                ),
              if (_dateFilter != 'All Time')
                Chip(
                  label: Text(_dateFilter),
                  backgroundColor: Colors.green.shade100,
                ),
              if (_sortBy != 'Date (Newest)')
                Chip(
                  label: Text(_sortBy),
                  backgroundColor: Colors.orange.shade100,
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: txQuery.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error loading transactions'));
              }
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(child: Text('No transactions yet!'));
              }

              // Filter transactions based on search query and filters
              var filteredDocs = docs.where((doc) {
                final transaction = doc.data();

                // Text search filter
                if (query.isNotEmpty) {
                  final description = transaction['description']?.toString().toLowerCase() ?? '';
                  final amount = transaction['amount']?.toString() ?? '';
                  final category = transaction['category']?.toString().toLowerCase() ?? '';
                  final searchLower = query.toLowerCase();

                  if (!description.contains(searchLower) &&
                      !amount.contains(searchLower) &&
                      !category.contains(searchLower)) {
                    return false;
                  }
                }

                // Income/Expense filter
                final isIncome = transaction['isIncome'] ?? false;
                if (_filterType == 'Income' && !isIncome) return false;
                if (_filterType == 'Expense' && isIncome) return false;

                // Date filter
                if (!_matchesDateFilter(transaction['date'])) return false;

                return true;
              }).toList();

              // Sort the filtered results
              filteredDocs.sort((a, b) {
                final transactionA = a.data();
                final transactionB = b.data();

                switch (_sortBy) {
                  case 'Date (Oldest)':
                    final dateA = transactionA['date'];
                    final dateB = transactionB['date'];
                    if (dateA is Timestamp && dateB is Timestamp) {
                      return dateA.compareTo(dateB);
                    }
                    return 0;
                  case 'Amount (High)':
                    final amountA = (transactionA['amount'] as num?)?.toDouble() ?? 0.0;
                    final amountB = (transactionB['amount'] as num?)?.toDouble() ?? 0.0;
                    return amountB.compareTo(amountA);
                  case 'Amount (Low)':
                    final amountA = (transactionA['amount'] as num?)?.toDouble() ?? 0.0;
                    final amountB = (transactionB['amount'] as num?)?.toDouble() ?? 0.0;
                    return amountA.compareTo(amountB);
                  case 'Date (Newest)':
                  default:
                    final dateA = transactionA['date'];
                    final dateB = transactionB['date'];
                    if (dateA is Timestamp && dateB is Timestamp) {
                      return dateB.compareTo(dateA);
                    }
                    return 0;
                }
              });

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Text('No transactions found${query.isNotEmpty ? ' for "$query"' : ''}'),
                );
              }

              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final transaction = filteredDocs[index].data();
                  final isIncome = transaction['isIncome'] ?? false;
                  final dateStr = _formatDate(transaction['date']);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncome ? Colors.green : Colors.red,
                      child: Icon(
                        isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      transaction['description'] ?? 'No description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transaction['category'] ?? 'No category'),
                        if (dateStr.isNotEmpty)
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    trailing: Text(
                      '${isIncome ? '+' : '-'}${transaction['amount']?.toString() ?? '0'}',
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
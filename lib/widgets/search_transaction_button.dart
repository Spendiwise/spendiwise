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
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
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

  Widget _buildSearchResults() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('User not logged in'));
    }

    // Same Firebase collection as transaction_list.dart
    final colRef = FirebaseFirestore.instance
        .collection('transactions')
        .doc(user.uid)
        .collection('transactions')
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snap, _) => snap.data()!,
      toFirestore: (map, _) => map,
    );

    // Query ordered by date descending (same as transaction_list.dart)
    final txQuery = colRef.orderBy('date', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

        // Filter transactions based on search query
        final filteredDocs = docs.where((doc) {
          final transaction = doc.data();
          final description = transaction['description']?.toString().toLowerCase() ?? '';
          final amount = transaction['amount']?.toString() ?? '';
          final category = transaction['category']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return description.contains(searchLower) ||
              amount.contains(searchLower) ||
              category.contains(searchLower);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text('No transactions found for "$query"'),
          );
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final transaction = filteredDocs[index].data();
            final isIncome = transaction['isIncome'] ?? false;

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
              subtitle: Text(
                transaction['category'] ?? 'No category',
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
    );
  }
}
import 'package:flutter/material.dart';

class EventsSubscriptionScreen extends StatefulWidget {
  const EventsSubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<EventsSubscriptionScreen> createState() => _EventsSubscriptionScreenState();
}

class _EventsSubscriptionScreenState extends State<EventsSubscriptionScreen> {
  // Map to store subscription status for each category
  Map<String, bool> subscriptionStatus = {
    'Holiday': false,
    'Travel': false,
    'Entertainment': false,
    'Shopping': false,
    'Online Shopping': false,
    'Food & Drinks': false,
    'Technology': false,
    'Sports': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Events Subscriptions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description text
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Choose categories to receive notifications about special deals and events:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            // List of categories
            Expanded(
              child: ListView.builder(
                itemCount: subscriptionStatus.length,
                itemBuilder: (context, index) {
                  String category = subscriptionStatus.keys.elementAt(index);
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Switch(
                        value: subscriptionStatus[category]!,
                        onChanged: (bool value) {
                          setState(() {
                            subscriptionStatus[category] = value;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
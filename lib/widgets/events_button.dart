// lib/widgets/events_button.dart
import 'package:flutter/material.dart';
import '../screens/events_subscription_screen.dart';

class EventsButton extends StatelessWidget {
  const EventsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EventsSubscriptionScreen(),
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
          children: const [
            Icon(Icons.event_available),
            SizedBox(height: 8),
            Text('Events'),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../screens/goal_screen.dart';

typedef GoalsUpdatedCallback = void Function(List<Map<String, dynamic>> updatedGoals);

class GoalsButton extends StatelessWidget {
  final double balance;
  final List<Map<String, dynamic>> goals;
  final GoalsUpdatedCallback onGoalsUpdated;

  GoalsButton({
    required this.balance,
    required this.goals,
    required this.onGoalsUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ElevatedButton(
        onPressed: () async {
          // Navigate to GoalScreen and wait for updated goals
          final updatedGoals = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalScreen(
                balance: balance,
                goals: List<Map<String, dynamic>>.from(goals),
              ),
            ),
          );

          // If goals are updated, call callback
          if (updatedGoals != null) {
            onGoalsUpdated(updatedGoals);
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
    );
  }
}

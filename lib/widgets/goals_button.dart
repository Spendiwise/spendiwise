import 'package:flutter/material.dart';
import '../screens/goal_screen.dart';

typedef GoalsUpdatedCallback = void Function(List<Map<String, dynamic>> updatedGoals);

class GoalsButton extends StatelessWidget {
  final double balance;
  final String email;
  final String? groupId;
  final int goalFlag;
  final GoalsUpdatedCallback onGoalsUpdated;

  GoalsButton({
    required this.balance,
    required this.email,
    this.groupId,
    required this.goalFlag,
    required this.onGoalsUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ElevatedButton(
        onPressed: () async {
          final updatedGoals = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalScreen(
                balance: balance,
                email: email,
                groupId: groupId,
                goalFlag: goalFlag,
              ),
            ),
          );

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

import 'package:flutter/material.dart';
import 'add_goal_screen.dart';

class GoalScreen extends StatefulWidget {
  final double balance; // Current balance from HomeScreen
  final List<Map<String, dynamic>> goals; // Goals passed from HomeScreen

  GoalScreen({required this.balance, required this.goals});

  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  late List<Map<String, dynamic>> goals; // Local copy of the goals list

  @override
  void initState() {
    super.initState();
    goals = widget.goals; // Initialize with goals from HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Goals')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];

                // Calculate progress dynamically based on balance
                double progress = widget.balance >= goal['target']
                    ? goal['target']
                    : widget.balance;

                return Card(
                  child: ListTile(
                    title: Text(goal['title']),
                    subtitle: Text(
                      'Progress: \$${progress.toStringAsFixed(2)} / \$${goal['target'].toStringAsFixed(2)}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          goals.removeAt(index);
                        });
                      },
                    ),
                    onTap: () async {
                      // Navigate to AddGoalScreen with the goal data for editing
                      final updatedGoal = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddGoalScreen(goal: goal),
                        ),
                      );

                      // If a goal was returned (edited), update it in the list
                      if (updatedGoal != null) {
                        setState(() {
                          goals[index] = updatedGoal;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Navigate to AddGoalScreen to add a new goal
              final newGoal = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddGoalScreen()),
              );

              // If a new goal was added, update the list
              if (newGoal != null) {
                setState(() {
                  goals.add(newGoal);
                });
              }
            },
            child: Text('Add New Goal'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Pass updated goals back to HomeScreen
          Navigator.pop(context, goals);
        },
        child: Icon(Icons.check),
      ),
    );
  }
}
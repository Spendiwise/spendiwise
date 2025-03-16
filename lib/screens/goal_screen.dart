import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tryout/controllers/goal_controller.dart';
import 'add_goal_screen.dart';

class GoalScreen extends StatefulWidget {
  final double balance;
  final String email;
  final String? groupId;
  final int goalFlag;

  GoalScreen({required this.balance, required this.email, this.groupId, required this.goalFlag});

  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  List<Map<String, dynamic>> goals = [];

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  Future<void> loadGoals() async {
    List<Map<String, dynamic>> fetchedGoals = await fetchGoals(
      email: widget.email,
      groupId: widget.groupId,
      goalFlag: widget.goalFlag,
    );
    setState(() {
      goals = fetchedGoals;
    });
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      // Delete goal from 'goals' collection
      await FirebaseFirestore.instance.collection('goals').doc(goalId).delete();
    } catch (e) {
      print("Error deleting goal: $e");
    }
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

                double target = (goal['target'] as num).toDouble();
                double balance = widget.balance.toDouble();
                double progress = balance >= target ? target : balance;

                return Card(
                  child: ListTile(
                    title: Text(goal['title']),
                    subtitle: Text(
                      'Progress: \$${progress.toStringAsFixed(2)} / \$${target.toStringAsFixed(2)}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        await deleteGoal(goal['id']); // Delete from Firestore
                        setState(() {
                          goals.removeAt(index); // Remove from UI
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newGoal = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddGoalScreen(
                    email: widget.email,
                    groupId: widget.groupId,
                    goalFlag: widget.goalFlag,
                  ),
                ),
              );

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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_goal_screen.dart';
import 'edit_goal_screen.dart';

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
  @override
  Widget build(BuildContext context) {
    // Determine query field based on goalFlag
    final String queryField = widget.goalFlag == 0 ? 'email' : 'groupId';
    final dynamic queryValue = widget.goalFlag == 0 ? widget.email : widget.groupId;

    return Scaffold(
      appBar: AppBar(title: Text('Your Goals')),
      body: Column(
        children: [
          Expanded(
            // Use StreamBuilder to listen to real-time changes in "goals" collection
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('goals')
                  .where(queryField, isEqualTo: queryValue)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final goalDocs = snapshot.data!.docs;
                if (goalDocs.isEmpty) {
                  return Center(child: Text('No goals found.'));
                }
                return ListView.builder(
                  itemCount: goalDocs.length,
                  itemBuilder: (context, index) {
                    final doc = goalDocs[index];
                    final goalData = doc.data() as Map<String, dynamic>;
                    final goalId = doc.id;
                    final title = goalData['title'] ?? '';
                    final target = (goalData['target'] as num).toDouble();
                    // Calculate progress based on widget.balance and target
                    final progress = widget.balance >= target ? target : widget.balance;

                    return Card(
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text(
                          'Progress: \$${progress.toStringAsFixed(2)} / \$${target.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit button
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditGoalScreen(
                                      goalId: goalId,
                                      currentTitle: title,
                                      currentTarget: target,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Delete button
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('goals').doc(goalId).delete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Button to add a new goal
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddGoalScreen(
                    email: widget.email,
                    groupId: widget.groupId,
                    goalFlag: widget.goalFlag,
                  ),
                ),
              );
            },
            child: Text('Add New Goal'),
          ),
        ],
      ),
    );
  }
}

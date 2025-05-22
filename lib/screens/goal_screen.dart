import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_goal_screen.dart';
import 'edit_goal_screen.dart';

class GoalScreen extends StatefulWidget {
  final double balance;
  final String email;
  final String? groupId;
  final int goalFlag;

  GoalScreen({
    required this.balance,
    required this.email,
    this.groupId,
    required this.goalFlag,
  });

  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  @override
  Widget build(BuildContext context) {
    final String queryField =
    widget.goalFlag == 0 ? 'email' : 'groupId';
    final dynamic queryValue =
    widget.goalFlag == 0 ? widget.email : widget.groupId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Goals'),
      ),
      // Floating button to add new goal
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddGoalScreen(
                email: widget.email,
                groupId: widget.groupId,
                goalFlag: widget.goalFlag,
              ),
            ),
          );
        },
        icon: Icon(Icons.add),
        label: Text('New Goal'),
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text('No goals found.'));
          }

          // Split into incomplete and completed
          final incomplete = <QueryDocumentSnapshot>[];
          final completed = <QueryDocumentSnapshot>[];
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final target = (data['target'] as num).toDouble();
            if (widget.balance >= target) {
              completed.add(doc);
            } else {
              incomplete.add(doc);
            }
          }

          Widget buildSection(String title, List<QueryDocumentSnapshot> items,
              {required bool isCompleted}) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(title,
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: Text('None')),
                  )
                else
                  ...items.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final goalId = doc.id;
                    final title = data['title'] as String;
                    final target = (data['target'] as num).toDouble();
                    final progress = widget.balance >= target
                        ? target
                        : widget.balance;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      color:
                      isCompleted ? Colors.green.shade300 : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                            isCompleted ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          isCompleted
                              ? 'Completed: \$${target.toStringAsFixed(2)}'
                              : 'Progress: \$${progress.toStringAsFixed(2)} / \$${target.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isCompleted
                                ? Colors.white70
                                : Colors.black87,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isCompleted) ...[
                              IconButton(
                                icon: Icon(Icons.edit,
                                    color: Colors.grey[800]),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditGoalScreen(
                                        goalId: goalId,
                                        currentTitle: title,
                                        currentTarget: target,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: isCompleted
                                      ? Colors.white
                                      : Colors.red),
                              onPressed: () async {
                                // delete goal
                                await FirebaseFirestore.instance
                                    .collection('goals')
                                    .doc(goalId)
                                    .delete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            );
          }

          return ListView(
            children: [
              buildSection('Incomplete Goals', incomplete,
                  isCompleted: false),
              buildSection('Completed Goals', completed,
                  isCompleted: true),
              SizedBox(height: 80), // space for FAB
            ],
          );
        },
      ),
    );
  }
}

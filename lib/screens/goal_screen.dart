// goal_screen.dart

import 'package:flutter/material.dart';
class AddGoalScreen extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController targetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add a Goal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Goal Title'),
            ),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Target Amount'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text;
                final target = double.tryParse(targetController.text);

                if (title.isNotEmpty && target != null) {
                  Navigator.pop(context, {
                    'title': title,
                    'target': target,
                    'progress': 0,
                  });
                }
              },
              child: Text('Save Goal'),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalScreen extends StatefulWidget {
  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  List<Map<String, dynamic>> goals = [
    {'title': 'Save for Vacation', 'target': 5000, 'progress': 2000},
    {'title': 'Buy a New Laptop', 'target': 1500, 'progress': 500},
  ];

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
                return Card(
                  child: ListTile(
                    title: Text(goal['title']),
                    subtitle: Text(
                      'Progress: \$${goal['progress']} / \$${goal['target']}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          goals.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddGoalScreen()),
              ).then((newGoal) {
                if (newGoal != null) {
                  setState(() {
                    goals.add(newGoal);
                  });
                }
              });
            },
            child: Text('Add New Goal'),
          ),
        ],
      ),
    );
  }
}

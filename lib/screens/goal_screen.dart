import 'package:flutter/material.dart';

// Add Goal Screen
class AddGoalScreen extends StatefulWidget {
  final Map<String, dynamic>? goal; // Accept goal data for editing

  AddGoalScreen({this.goal}); // Constructor to pass the goal for editing

  @override
  _AddGoalScreenState createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController targetController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // If editing an existing goal, populate fields with the goal data
    if (widget.goal != null) {
      titleController.text = widget.goal!['title'];
      targetController.text = widget.goal!['target'].toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.goal != null ? 'Edit Goal' : 'Add a Goal')),
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
                  // Return the goal data back to the previous screen (for add/edit)
                  Navigator.pop(context, {
                    'title': title,
                    'target': target, // Make sure it's a double
                    'progress': widget.goal?['progress'] ?? 0.0, // Keep previous progress if editing
                  });
                }
              },
              child: Text(widget.goal != null ? 'Save Changes' : 'Save Goal'),
            ),
          ],
        ),
      ),
    );
  }
}

// Goal Screen
class GoalScreen extends StatefulWidget {
  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  List<Map<String, dynamic>> goals = [
    {'title': 'Save for Vacation', 'target': 5000.0, 'progress': 2000.0},
    {'title': 'Buy a New Laptop', 'target': 1500.0, 'progress': 500.0},
  ];

  @override
  Widget build(BuildContext context) {
    double balance = 1500.50; // Get balance from elsewhere (e.g., shared preferences or a state manager)

    return Scaffold(
      appBar: AppBar(title: Text('Your Goals')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];

                // Update progress based on balance
                double progress = goal['target'] <= balance ? goal['target'] : balance;

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
                          builder: (context) => AddGoalScreen(goal: goal), // Pass goal for editing
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
    );
  }
}

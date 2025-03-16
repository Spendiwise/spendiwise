import 'package:flutter/material.dart';
import 'package:tryout/controllers/goal_controller.dart';

class EditGoalScreen extends StatefulWidget {
  final String goalId;
  final String currentTitle;
  final double currentTarget;

  EditGoalScreen({required this.goalId, required this.currentTitle, required this.currentTarget});

  @override
  _EditGoalScreenState createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  late TextEditingController titleController;
  late TextEditingController targetController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.currentTitle);
    targetController = TextEditingController(text: widget.currentTarget.toString());
  }

  @override
  void dispose() {
    titleController.dispose();
    targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Goal')),
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
              onPressed: () async {
                final newTitle = titleController.text;
                final newTarget = double.tryParse(targetController.text);

                if (newTitle.isNotEmpty && newTarget != null) {
                  await updateGoal(goalId: widget.goalId, newTitle: newTitle, newTarget: newTarget);
                  Navigator.pop(context, {'title': newTitle, 'target': newTarget});
                }
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

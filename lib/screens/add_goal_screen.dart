import 'package:flutter/material.dart';
import 'package:tryout/controllers/goal_controller.dart';

class AddGoalScreen extends StatefulWidget {
  final String email;
  final String? groupId;
  final int goalFlag;

  AddGoalScreen({required this.email, this.groupId, required this.goalFlag});

  @override
  _AddGoalScreenState createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
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
              onPressed: () async {
                final title = titleController.text;
                final target = double.tryParse(targetController.text);

                if (title.isNotEmpty && target != null) {
                  await addGoalToFirestore(
                    title: title,
                    target: target,
                    email: widget.email,
                    groupId: widget.groupId,
                    goalFlag: widget.goalFlag,
                  );

                  Navigator.pop(context, {
                    'title': title,
                    'target': target,
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

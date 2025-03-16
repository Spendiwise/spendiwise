import 'package:flutter/material.dart';
import 'package:tryout/controllers/goal_controller.dart';

class AddGoalScreen extends StatefulWidget {
  final String email;
  final String? groupId;
  final int goalFlag;

  const AddGoalScreen({super.key, required this.email, this.groupId, required this.goalFlag});

  @override
  AddGoalScreenState createState() => AddGoalScreenState();
}

class AddGoalScreenState extends State<AddGoalScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController targetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Goal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Goal Title'),
            ),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target Amount'),
            ),
            const SizedBox(height: 20),
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

                  if (context.mounted) {
                    Navigator.pop(context, {
                      'title': title,
                      'target': target,
                    });
                  }
                }
              },
              child: const Text('Save Goal'),
            ),
          ],
        ),
      ),
    );
  }
}

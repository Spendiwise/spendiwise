import 'package:flutter/material.dart';

class AddGoalScreen extends StatefulWidget {
  final Map<String, dynamic>? goal; // Accept goal data for editing

  AddGoalScreen({this.goal});

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
      appBar: AppBar(
        title: Text(widget.goal != null ? 'Edit Goal' : 'Add a Goal'),
      ),
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
                    'target': target, // Target as a double
                    'progress': widget.goal?['progress'] ?? 0.0, // Keep progress for editing
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

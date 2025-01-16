import 'package:flutter/material.dart';
import '../../controllers/random_code_generator.dart';
import 'waitings_screen.dart';

class MembersScreen extends StatefulWidget {
  final String groupName;

  MembersScreen({required this.groupName});

  @override
  _MembersScreenState createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  // Members list with initial roles
  final List<Map<String, String>> members = [
    {'name': 'person 1', 'role': 'admin'},
    {'name': 'person 2', 'role': 'user'},
    {'name': 'person 3', 'role': 'viewer'},
  ];

  final List<String> roles = ['admin', 'user', 'viewer']; // Available roles

  @override
  Widget build(BuildContext context) {
    final groupCode = RandomCodeGenerator.generateCode();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Members of ${widget.groupName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 16),
            // Two-column structure for members
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return Row(
                    children: [
                      // Display member name
                      Expanded(
                        child: Text(member['name']!,
                            style: TextStyle(fontSize: 16)),
                      ),
                      // Role dropdown menu
                      Expanded(
                        child: DropdownButton<String>(
                          value: member['role'],
                          items: roles.map((String role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: (String? newRole) {
                            setState(() {
                              members[index]['role'] = newRole!;
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WaitingsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Waitings'),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showInviteBottomSheet(context, groupCode);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteBottomSheet(BuildContext context, String groupCode) {
    final TextEditingController emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Group Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: groupCode,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Send Invitation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Enter Email',
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Send Invitation'),
              ),
            ],
          ),
        );
      },
    );
  }
}
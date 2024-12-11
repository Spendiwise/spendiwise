// lib/screens/groupWallet/join_group_screen.dart

import 'package:flutter/material.dart';

class JoinGroupScreen extends StatefulWidget {
  @override
  _JoinGroupScreenState createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final TextEditingController groupCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Group'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: groupCodeController,
                decoration: InputDecoration(
                  labelText: 'Group Code',
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  //TODO: For now, just go back and do nothing. In the future, we will need implement join
                  Navigator.pop(context);
                },
                child: Text('Join'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

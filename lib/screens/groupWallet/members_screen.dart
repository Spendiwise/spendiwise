import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../screens/main_wallet_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String email;

  MembersScreen({required this.groupId, required this.groupName, required this.email});

  @override
  _MembersScreenState createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? groupCode;
  List<String> members = [];

  @override
  void initState() {
    super.initState();
    _fetchGroupCode();
  }

  Future<void> _fetchGroupCode() async {
    try {
      DocumentSnapshot snapshot = await firestore.collection('wallets').doc(widget.groupId).get();
      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          groupCode = snapshot['code'];
          members = List<String>.from(snapshot['members'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching group code: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load group details.')));
    }
  }

  Future<void> _copyGroupCode() async {
    if (groupCode != null) {
      await Clipboard.setData(ClipboardData(text: groupCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group Code copied to clipboard!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group Code is not available!')),
      );
    }
  }

  Future<void> _removeMemberFromGroup() async {
    try {
      // Delete user email in 'members' list
      await firestore.collection('wallets').doc(widget.groupId).update({
        'members': FieldValue.arrayRemove([widget.email]),
      });

      // Update UI
      setState(() {
        members.remove(widget.email);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have successfully left the group!')),
      );

      // Redirect user to MainWalletScreen
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainWalletScreen()));

    } catch (e) {
      print('Error removing user from group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to leave the group. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('${widget.groupName} Members'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupCode(),
            SizedBox(height: 20),
            Text(
              'Members:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            _buildMembersList(),
            SizedBox(height: 20),
            // Leave group button
            ElevatedButton(
              onPressed: _removeMemberFromGroup,
              child: Text('Leave Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCode() {
    if (groupCode == null) {
      return Center(child: CircularProgressIndicator()); // Group code loading
    } else {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Group Code: $groupCode",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy, color: Colors.white),
              onPressed: _copyGroupCode,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMembersList() {
    if (members.isEmpty) {
      return Center(child: Text('No members available'));
    } else {
      return Expanded(
        child: ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 5),
              elevation: 3,
              child: ListTile(
                leading: Icon(Icons.person, color: Colors.blue),
                title: Text(
                  members[index],
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          },
        ),
      );
    }
  }
}

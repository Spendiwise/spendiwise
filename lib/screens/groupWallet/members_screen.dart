import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class MembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  MembersScreen({required this.groupId, required this.groupName});

  @override
  _MembersScreenState createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
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
            groupCode == null
                ? Center(child: CircularProgressIndicator()) // Group code loading
                : Container(
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
            ),
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

            // Members list
            members.isEmpty
                ? Center(child: CircularProgressIndicator()) // Members loading
                : Expanded(
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
            ),
          ],
        ),
      ),
    );
  }
}

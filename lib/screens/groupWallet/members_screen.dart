import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'waitings_screen.dart';

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
        });
      }
    } catch (e) {
      print('Error fetching group code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Members of ${widget.groupName}'),
      ),
      body: Center(
        child: groupCode == null
            ? CircularProgressIndicator() // 🔹 Kod yüklenene kadar bekletir
            : Text("Group Code: $groupCode"),
      ),
    );
  }
}

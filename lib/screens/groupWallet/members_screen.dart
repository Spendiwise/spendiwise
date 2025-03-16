import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../screens/main_wallet_screen.dart';
import 'package:flutter/foundation.dart';

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
  String? groupCode;
  String? groupDescription;
  List<String> members = [];
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    DocumentSnapshot snapshot = await firestore.collection('wallets').doc(widget.groupId).get();
    if (snapshot.exists && snapshot.data() != null) {
      setState(() {
        groupCode = snapshot['code'];
        groupDescription = snapshot['description'] ?? 'No description available';
        members = List<String>.from(snapshot['members'] ?? []);
      });
    }
  }

  Future<void> _copyGroupCode() async {
    if (groupCode != null) {
      await Clipboard.setData(ClipboardData(text: groupCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group Code copied to clipboard!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group Code is not available!')),
      );
    }
  }

  Future<void> _removeMemberFromGroup() async {
    DocumentReference groupRef = firestore.collection('wallets').doc(widget.groupId);

    // Remove user email from 'members' list
    await groupRef.update({
      'members': FieldValue.arrayRemove([widget.email]),
    });

    // Get the updated document to check if any members are left
    DocumentSnapshot updatedGroup = await groupRef.get();
    List<dynamic> updatedMembers = updatedGroup['members'] ?? [];

    // If the members list is empty, delete group completely.
    if (updatedMembers.isEmpty) {
      await groupRef.delete();
      if (kDebugMode) {
        print('Group deleted because no members left.');
      }
    }

    // Update UI
    setState(() {
      members.remove(widget.email);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have successfully left the group!')),
    );

    // Redirect user to MainWalletScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainWalletScreen()),
    );
  }

  Future<void> _updateGroupDescription() async {
    if (descriptionController.text.isNotEmpty) {
        await firestore.collection('wallets').doc(widget.groupId).update({
          'description': descriptionController.text,
        });
        setState(() {
          groupDescription = descriptionController.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group description updated successfully!')),
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
            _buildGroupDescription(),
            const SizedBox(height: 10),
            _buildGroupCode(),
            const SizedBox(height: 20),
            const Text(
              'Members:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            _buildMembersList(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _removeMemberFromGroup,
              child: const Text('Leave Group'),
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
      return const Center(child: CircularProgressIndicator()); // Group code loading
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Group Code: $groupCode",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              onPressed: _copyGroupCode,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMembersList() {
    if (members.isEmpty) {
      return const Center(child: Text('No members available'));
    } else {
      return Expanded(
        child: ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text(
                  members[index],
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildGroupDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.green, // GreenAccent used for background color
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Description: ", // Title for description
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  groupDescription ?? 'No description available', // Display description
                  style: const TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis, // Handles long text gracefully
                  maxLines: 2, // Limits to 2 lines
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  descriptionController.text = groupDescription ?? '';
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Edit Group Description'),
                        content: TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(hintText: 'Enter new description'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _updateGroupDescription();
                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

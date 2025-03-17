import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'members_actions.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.groupName),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    MembersActions.inviteUser(
                      firestore: firestore,
                      groupId: widget.groupId,
                      context: context,
                      members: members,
                      addMemberCallback: (invitedEmail) {
                        setState(() {
                          members.add(invitedEmail);
                        });
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Invite User'),
                ),
                ElevatedButton(
                  onPressed: () {
                    MembersActions.removeMemberFromGroup(
                      firestore: firestore,
                      groupId: widget.groupId,
                      email: widget.email,
                      context: context,
                      removeMemberCallback: (removedEmail) {
                        setState(() {
                          members.remove(removedEmail);
                        });
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Leave Group'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCode() {
    if (groupCode == null) {
      return const Center(child: CircularProgressIndicator());
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
              onPressed: () => MembersActions.copyGroupCode(groupCode, context),
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
            color: Colors.green,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Description: ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  groupDescription ?? 'No description available',
                  style: const TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
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
                              MembersActions.updateGroupDescription(
                                firestore: firestore,
                                groupId: widget.groupId,
                                newDescription: descriptionController.text,
                                context: context,
                                updateDescriptionCallback: (newDesc) {
                                  setState(() {
                                    groupDescription = newDesc;
                                  });
                                },
                              );
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
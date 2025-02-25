import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  final String currentUserId;

  SearchScreen({required this.currentUserId});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  List<String> _chattedUserIds = [];

  @override
  void initState() {
    super.initState();
    _fetchChattedUserIds();
  }

  void _fetchChattedUserIds() async {
    // Fetch user IDs that the current user has chatted with
    QuerySnapshot chatSnapshot = await FirebaseFirestore.instance.collection('chats')
        .where('receiverId', isEqualTo: widget.currentUserId)
        .get();

    // Add sender IDs to the list
    List<String> senderIds = chatSnapshot.docs.map((doc) {
      return doc['senderId'] as String;
    }).toList();

    // Fetch chats where the current user is the sender
    QuerySnapshot senderChatSnapshot = await FirebaseFirestore.instance.collection('chats')
        .where('senderId', isEqualTo: widget.currentUserId)
        .get();

    // Add receiver IDs to the list
    List<String> receiverIds = senderChatSnapshot.docs.map((doc) {
      return doc['receiverId'] as String;
    }).toList();

    // Combine the IDs and remove duplicates
    _chattedUserIds = (senderIds + receiverIds).toSet().toList();
  }

  void _searchUsers() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: _searchController.text.trim())
        .where('username', isLessThanOrEqualTo: _searchController.text.trim() + '\uf8ff') // For case-insensitive search
        .get();

    setState(() {
      _searchResults = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((user) => user.username.isNotEmpty 
                            && user.id != widget.currentUserId 
                            && _chattedUserIds.contains(user.id)) // Only include chatted users
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Search Users', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 155, 33, 55), // Custom color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by username',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
              style: TextStyle(color: Colors.white),
              onChanged: (value) => _searchUsers(),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return Card(
                    color: Color.fromARGB(255, 32, 32, 32),
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    elevation: 4,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        user.username,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              currentUserId: widget.currentUserId,
                              chatUserId: user.id,
                              chatUsername: user.username,
                            ),
                          ),
                        );
                      },
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
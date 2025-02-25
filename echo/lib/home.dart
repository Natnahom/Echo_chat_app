import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart'; 
import 'user_model.dart'; 
import 'search_screen.dart'; 
import 'search_users.dart'; 
import 'profile.dart';
import 'settings.dart' as echo_settings;

class HomeScreen extends StatelessWidget {
  final String currentUserId;

  HomeScreen({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 155, 33, 55),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen(currentUserId: currentUserId)),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Color.fromARGB(255, 32, 32, 32),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 155, 33, 55),
              ),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(child: Text('User not found', style: TextStyle(color: Colors.white)));
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  final username = userData['username'] ?? 'User';

                  return Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        radius: 30,
                        child: Text(
                          username[0].toUpperCase(),
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                      SizedBox(height: 30),
                      Text(
                        username,
                        style: TextStyle(color: const Color.fromARGB(255, 132, 132, 132), fontSize: 24),
                      ),
                    ],
                  );
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.white),
              title: Text('My Profile', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Profile(userId: currentUserId,))); 
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.white),
              title: Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => echo_settings.Settings()));
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.black,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('chats')
              .where('receiverId', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
            }

            final chatDocs = snapshot.data!.docs;

            // Get a list of user IDs that the current user has chatted with
            List<String> chattedUserIds = chatDocs.expand((doc) {
              List<String> ids = [];
              if (doc['receiverId'] != currentUserId) {
                ids.add(doc['receiverId']);
              }
              if (doc['senderId'] != currentUserId) {
                ids.add(doc['senderId']);
              }
              return ids;
            }).toSet().toList();

            if (chattedUserIds.isEmpty) {
              return Center(
                child: Text(
                  'You haven\'t chatted with anyone yet.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            // Load user data for those user IDs and count unread messages
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users')
                  .where(FieldPath.documentId, whereIn: chattedUserIds)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (userSnapshot.hasError) {
                  return Center(child: Text('Error: ${userSnapshot.error}', style: TextStyle(color: Colors.white)));
                }

                final users = userSnapshot.data!.docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return UserModel.fromMap(data, doc.id);
                    })
                    .where((user) => user.username.isNotEmpty)
                    .toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'You haven\'t chatted with anyone yet.',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }

                // Create a list to hold user unread counts and latest message timestamp
                List<Map<String, dynamic>> userUnreadCounts = [];

                // Get unread message counts and latest message timestamp for each user
                for (var user in users) {
                  int unreadCount = 0;
                  DateTime? latestMessageTime;

                  final userChats = chatDocs.where((doc) =>
                      (doc['senderId'] == user.id && doc['receiverId'] == currentUserId) ||
                      (doc['receiverId'] == user.id && doc['senderId'] == currentUserId));

                  unreadCount = userChats.where((doc) => doc['read'] == false).length;

                  // Find the latest message timestamp
                  if (userChats.isNotEmpty) {
                    latestMessageTime = userChats.map((doc) => (doc['timestamp'] as Timestamp).toDate()).reduce((a, b) => a.isAfter(b) ? a : b);
                  }

                  userUnreadCounts.add({
                    'user': user,
                    'unreadCount': unreadCount,
                    'latestMessageTime': latestMessageTime,
                  });
                }

                // Sort users by latest message time and unread count
                userUnreadCounts.sort((a, b) {
                  if (b['latestMessageTime'] == null && a['latestMessageTime'] == null) {
                    return 0;
                  } else if (b['latestMessageTime'] == null) {
                    return -1;
                  } else if (a['latestMessageTime'] == null) {
                    return 1;
                  } else {
                    return b['latestMessageTime'].compareTo(a['latestMessageTime']);
                  }
                });

                // ListView to display users with unread counts
                return ListView.builder(
                  itemCount: userUnreadCounts.length,
                  itemBuilder: (context, index) {
                    final userInfo = userUnreadCounts[index];
                    final user = userInfo['user'];
                    final unreadCount = userInfo['unreadCount'];

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
                        subtitle: unreadCount > 0
                            ? 
                            Text(
                                '$unreadCount unread messages',
                                style: TextStyle(color: Colors.red),
                              )
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                currentUserId: currentUserId, 
                                chatUserId: user.id,
                                chatUsername: user.username,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchUsers(currentUserId: currentUserId)),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Color.fromARGB(255, 155, 33, 55),
      ),
    );
  }
}
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'user_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for formatting timestamps

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String chatUserId;
  final String chatUsername;

  ChatScreen({required this.currentUserId, required this.chatUserId, required this.chatUsername});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late CollectionReference _messages;
  String? _editingMessageId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages = FirebaseFirestore.instance.collection('chats');
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() {
    _messages
        .where('senderId', isEqualTo: widget.chatUserId)
        .where('receiverId', isEqualTo: widget.currentUserId)
        .where('read', isEqualTo: false) // Only update unread messages
        .get()
        .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.update({'read': true}); // Update the read status
          }
        });
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      if (_editingMessageId != null) {
        // Update existing message
        _messages.doc(_editingMessageId).update({
          'text': _messageController.text,
          // 'timestamp': FieldValue.serverTimestamp(), // Uncomment if you want to update the timestamp as well
        }).then((_) {
          _messageController.clear();
          setState(() {
            _editingMessageId = null; // Clear editing state
          });
        });
      } else {
        // Add new message
        _messages.add({
          'read': false, // Initial unread status
          'text': _messageController.text,
          'senderId': widget.currentUserId,
          'receiverId': widget.chatUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _messageController.clear();
      }
    }
  }

  void _editMessage(String messageId, String messageText) {
    setState(() {
      _editingMessageId = messageId;
      _messageController.text = messageText; // Populate the text field for editing
    });
  }

  void _deleteMessage(String messageId) {
    _messages.doc(messageId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatUsername),
        backgroundColor: Color.fromARGB(255, 155, 33, 55), // Same as home bar
      ),
      body: Container(
        color: Color.fromARGB(255, 32, 32, 32), // Set body color
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<DocumentSnapshot>>(
                stream: Rx.combineLatest2(
                  _messages
                      .where('senderId', isEqualTo: widget.currentUserId)
                      .where('receiverId', isEqualTo: widget.chatUserId)
                      .orderBy('timestamp')
                      .snapshots(),
                  _messages
                      .where('senderId', isEqualTo: widget.chatUserId)
                      .where('receiverId', isEqualTo: widget.currentUserId)
                      .orderBy('timestamp')
                      .snapshots(),
                  (QuerySnapshot a, QuerySnapshot b) {
                    final combinedDocs = [...a.docs, ...b.docs];
                    combinedDocs.sort((a, b) =>
                        a['timestamp'].compareTo(b['timestamp']));
                    return combinedDocs;
                  },
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final messages = snapshot.data ?? [];
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Scroll to the bottom when a new message is added
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSender = message['senderId'] == widget.currentUserId;

                      return Align(
                        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: () {
                            // Show options for edit and delete
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Choose an option'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        _editMessage(message.id, message['text']);
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Edit'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _deleteMessage(message.id);
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSender ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  message['text'],
                                  style: TextStyle(color: isSender ? Colors.white : Colors.black),
                                ),
                                SizedBox(height: 5), // Add space between text and timestamp
                                Text(
                                  _formatTimestamp(message['timestamp']),
                                  style: TextStyle(fontSize: 12, color: const Color.fromARGB(255, 53, 50, 50)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(labelText: 'Send a message...'),
                      style: TextStyle(color: Colors.white), // Change text color
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.white,),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy/MM/dd | hh:mm a').format(dateTime); 
  }
}
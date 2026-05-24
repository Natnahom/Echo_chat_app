import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String chatUserId;
  final String chatUsername;

  const ChatScreen({
    Key? key,
    required this.currentUserId,
    required this.chatUserId,
    required this.chatUsername,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late CollectionReference _messages;
  String? _editingMessageId;
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages = FirebaseFirestore.instance.collection('chats');
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markMessagesAsRead() {
    _messages
        .where('senderId', isEqualTo: widget.chatUserId)
        .where('receiverId', isEqualTo: widget.currentUserId)
        .where('read', isEqualTo: false)
        .get()
        .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.update({'read': true});
          }
        }).catchError((error) {
          print("Error marking messages as read: $error");
        });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      if (_editingMessageId != null) {
        // Update existing message
        await _messages.doc(_editingMessageId).update({
          'text': _messageController.text.trim(),
          'edited': true,
          'editedAt': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          _editingMessageId = null;
        });
      } else {
        // Add new message
        await _messages.add({
          'read': false,
          'text': _messageController.text.trim(),
          'senderId': widget.currentUserId,
          'receiverId': widget.chatUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'edited': false,
        });
      }
      
      _messageController.clear();
      
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $error')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _editMessage(String messageId, String messageText) {
    setState(() {
      _editingMessageId = messageId;
      _messageController.text = messageText;
    });
    
    // Focus on text field when editing
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _messages.doc(messageId).update({
          'lifecycleStatus': 'DELETED',
          'editorId': widget.currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $error')),
      );
    }
  }

  void _showDeleteConfirmation(String messageId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 45, 45, 45),
          title: const Text('Delete Message', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to delete this message?', 
            style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(messageId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _cancelEditing() {
    setState(() {
      _editingMessageId = null;
      _messageController.clear();
    });
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime dateTime = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 7) {
        return DateFormat('MMM d, yyyy').format(dateTime);
      } else if (difference.inDays > 1) {
        return DateFormat('EEE').format(dateTime);
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return DateFormat('hh:mm a').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatUsername),
        backgroundColor: const Color.fromARGB(255, 155, 33, 55),
        actions: [
          if (_editingMessageId != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEditing,
              tooltip: 'Cancel editing',
            ),
        ],
      ),
      body: Container(
        color: const Color.fromARGB(255, 32, 32, 32),
        child: Column(
          children: [
            // Editing indicator
            if (_editingMessageId != null)
              Container(
                color: Colors.blue.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Editing message',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<List<DocumentSnapshot>>(
                stream: Rx.combineLatest2(
                  _messages
                      .where('senderId', isEqualTo: widget.currentUserId)
                      .where('receiverId', isEqualTo: widget.chatUserId)
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  _messages
                      .where('senderId', isEqualTo: widget.chatUserId)
                      .where('receiverId', isEqualTo: widget.currentUserId)
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  (QuerySnapshot a, QuerySnapshot b) {
                    final combinedDocs = [...a.docs, ...b.docs];
                    combinedDocs.sort((a, b) {
                      // Handle null timestamps
                      final aTime = a['timestamp'] as Timestamp?;
                      final bTime = b['timestamp'] as Timestamp?;
                      
                      if (aTime == null && bTime == null) return 0;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      
                      return aTime.compareTo(bTime);
                    });
                    return combinedDocs;
                  },
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet.\nStart a conversation!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    );
                  }

                  // Scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSender = message['senderId'] == widget.currentUserId;
                      final isEdited = message['edited'] == true;

                      String status = 'ACTIVE';
                      try{
                        status = message['lifecycleStatus'] ?? 'ACTIVE';
                      } catch (e) {
                        // If lifecycleStatus is missing, default to ACTIVE
                        status = 'ACTIVE';
                      }

                      final isDeleted = status == 'DELETED';

                      final String displaySnapshotText = isDeleted 
                        ? {
                            'ACTIVE': message['text'],
                            'DELETED': '🚫 MESSAGE DELETED',
                          }[status] ?? message['text']
                        
                        : message['text'];

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isSender)
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.grey[600],
                                child: Text(
                                  widget.chatUsername[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSender 
                                    ? const Color.fromARGB(255, 155, 33, 55) 
                                    : const Color.fromARGB(255, 45, 45, 45),
                                  borderRadius: BorderRadius.circular(16).copyWith(
                                    bottomRight: isSender ? const Radius.circular(4) : const Radius.circular(16),
                                    bottomLeft: !isSender ? const Radius.circular(4) : const Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      displaySnapshotText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (isEdited)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          'edited',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white54,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatTimestamp(message['timestamp']),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white54,
                                          ),
                                        ),
                                        if (isSender) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            message['read'] == true 
                                              ? Icons.done_all 
                                              : Icons.done,
                                            size: 12,
                                            color: message['read'] == true 
                                              ? Colors.blue 
                                              : Colors.white54,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isSender)
                              PopupMenuButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                                color: const Color.fromARGB(255, 45, 45, 45),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editMessage(message.id, message['text']);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation(message.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit', style: TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red, size: 18),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Message input area
            Container(
              color: const Color.fromARGB(255, 45, 45, 45),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _editingMessageId != null 
                          ? 'Edit message...' 
                          : 'Send a message...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _editingMessageId != null ? Icons.check : Icons.send,
                      color: _messageController.text.trim().isEmpty 
                        ? Colors.white38 
                        : Colors.white,
                    ),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
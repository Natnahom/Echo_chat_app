import 'package:flutter/material.dart';
MaterialColor customColor = MaterialColor(
  0xFF1E1F259, // The primary color value
  <int, Color>{
    50: Color(0xFF1E1F25), // 10%
    100: Color(0xFF1E1F25), // 20%
    200: Color(0xFF1E1F25), // 30%
    300: Color(0xFF1E1F25), // 40%
    400: Color(0xFF1E1F25), // 50%
    500: Color(0xFF1E1F25), // 60%
    600: Color(0xFF1E1F25), // 70%
    700: Color(0xFF1E1F25), // 80%
    800: Color(0xFF1E1F25), // 90%
    900: Color(0xFF1E1F25), // 100%
  },
);

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: customColor, // Use the custom MaterialColor
      ),
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<String> _messages = [];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add(_controller.text);
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 222, 76, 76),
        title: Row(
          children: [
            CircleAvatar(
              child: Icon(Icons.person),
            ),
            SizedBox(width: 10),
            Text('Profile Name'),
          ],
        ),
      ),
      body: Container(
        color: Color.fromARGB(255, 34, 37, 42),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      _messages[index],
                      style: TextStyle(color: Colors.white),
                    ),
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
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Enter your message',
                        hintStyle: TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send),
                    color: Colors.grey[400],
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
}

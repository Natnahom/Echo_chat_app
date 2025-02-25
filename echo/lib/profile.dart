import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Profile extends StatefulWidget {
  final String userId; // Pass the user ID to fetch their data

  const Profile({super.key, required this.userId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late Future<Map<String, dynamic>> _userData;

  @override
  void initState() {
    super.initState();
    _userData = _fetchUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    return snapshot.data() as Map<String, dynamic>;
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    // Navigate to the login screen
    Navigator.of(context).pushReplacementNamed('/login'); // Adjust the route name accordingly
  }

  void _editProfile() {
    // Navigate to the edit profile screen
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => EditProfileScreen(userId: widget.userId), // Assuming you have an EditProfileScreen
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 155, 33, 55), // Custom color
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('User not found'));
          }

          final userData = snapshot.data!;
          final username = userData['username'] ?? 'User';
          final email = userData['email'] ?? 'No email provided';

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    child: Text(
                      username[0].toUpperCase(), // Display the first letter of the username
                      style: TextStyle(fontSize: 40, color: Colors.white),
                    ),
                    backgroundColor: Color.fromARGB(255, 155, 33, 55), // Background color for the avatar
                  ),
                  SizedBox(height: 16),
                  Text(username, style: TextStyle(fontSize: 24, color: Colors.white)),
                  SizedBox(height: 8),
                  Text(email, style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 24),
                  TextButton(
                    onPressed: _editProfile,
                    child: Text('Edit Profile', style: TextStyle(color: Colors.black,)),
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(Size(70, 50)),
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: _logout,
                    child: Text('Logout', style: TextStyle(color: Colors.black,)),
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(Size(70, 50)),
                      backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 254, 17, 0)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      backgroundColor: Colors.black,
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final userData = snapshot.data() as Map<String, dynamic>;

    _usernameController.text = userData['username'] ?? '';
    _emailController.text = userData['email'] ?? '';
  }

  Future<void> _saveProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      // Re-authenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _passwordController.text, // Prompt for the current password
      );

      await user.reauthenticateWithCredential(credential);

      // Update Firestore immediately
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'username': _usernameController.text,
        'email': _emailController.text,
      });

      // Attempt to update Firebase Auth email
      try {
        await user.updateEmail(_emailController.text);
        // If successful, send verification email
        await user.sendEmailVerification();
        
        // Inform the user
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Profile updated successfully! A verification email has been sent.'),
        ));
        Navigator.of(context).pop(); // Go back to the profile screen
      } catch (e) {
        // Handle email update error (e.g., if the email is not verified)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: Please verify your new email address before changing it.'),
        ));
      }
    } catch (e) {
      // Handle re-authentication error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Color.fromARGB(255, 155, 33, 55),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username',),
              style: TextStyle(color: Colors.white),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'New Password (enter your old password to save changes)'),
              style: TextStyle(color: Colors.white),
              obscureText: true,
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: _saveProfile,
              child: Text('Save'),
              style: ButtonStyle(
                minimumSize: MaterialStateProperty.all(Size(70, 50)),
                backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 155, 33, 55)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
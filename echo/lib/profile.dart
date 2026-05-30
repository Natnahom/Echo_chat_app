import 'dart:convert';
import 'package:crypto/crypto.dart';
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('User not found'));
          }

          final userData = snapshot.data!;
          final username = userData['username'] ?? 'User';
          final email = userData['email'] ?? 'No email provided';
          final bio = userData['bio'] ?? 'No bio set.';
          final versionId = userData['profileVersionId'] ?? 1;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color.fromARGB(255, 155, 33, 55),
                      child: Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(fontSize: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(username, style: const TextStyle(fontSize: 24, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      'Profile Baseline v$versionId',
                      style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 8),
                    Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Text(
                      bio,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _editProfile,
                      child: const Text('Edit Profile', style: TextStyle(color: Colors.black)),
                      style: ButtonStyle(
                        minimumSize: MaterialStateProperty.all(const Size(70, 50)),
                        backgroundColor: MaterialStateProperty.all(Colors.white),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _logout,
                      child: const Text('Logout', style: TextStyle(color: Colors.black)),
                      style: ButtonStyle(
                        minimumSize: MaterialStateProperty.all(const Size(70, 50)),
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

  const EditProfileScreen({super.key, required this.userId});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController(); // Added Bio controller
  final TextEditingController _passwordController = TextEditingController();
  
  int _currentVersionId = 1;
  List<dynamic> _existingHashes = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final userData = snapshot.data() as Map<String, dynamic>;

    setState(() {
      _usernameController.text = userData['username'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _bioController.text = userData['bio'] ?? '';
      _currentVersionId = userData['profileVersionId'] ?? 1;
      _existingHashes = userData['archivedHashes'] ?? [];
    });
  }

  Future<void> _saveProfile() async {
    final newUsername = _usernameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newBio = _bioController.text.trim();

    // 1. STRICT SCHEMA VALIDATION CHECK
    if (newUsername.isEmpty || newEmail.isEmpty) {
      _showSnackBar('Schema Validation Failed: Username and Email fields cannot be null.');
      return;
    }
    if (newUsername.length < 3 || newUsername.length > 20) {
      _showSnackBar('Schema Validation Failed: Username must be 3-20 characters.');
      return;
    }
    if (newBio.length > 150) {
      _showSnackBar('Schema Validation Failed: Bio cannot exceed 150 characters.');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showSnackBar('Re-authentication required: Enter current password to sign modifications.');
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;

      // Re-authenticate user for explicit validation signature
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. INCREMENT IDENTITY BASELINE CONFIGURATION
      int nextVersionId = _currentVersionId + 1;

      // Generate a cryptographic hash of the previous state configuration data state before mutating 
      final String legacyStateString = "username:${_usernameController.text}|email:${_emailController.text}|bio:${_bioController.text}|version:$_currentVersionId";
      final String legacyStateHash = sha256.convert(utf8.encode(legacyStateString)).toString();
      
      // Update local baseline matrix tracking array
      List<String> updatedHashes = List<String>.from(_existingHashes);
      if (!updatedHashes.contains(legacyStateHash)) {
        updatedHashes.add(legacyStateHash);
      }

      // 3. COMMIT SCM COMPLIANT SCHEMA PACK TO FIRESTORE
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'username': newUsername,
        'email': newEmail,
        'bio': newBio,
        'profileVersionId': nextVersionId, // Incremented Version ID
        'archivedHashes': updatedHashes,     // Preserves Configuration Integrity Chain
      });

      // Attempt to safely transition Auth Email mapping
      try {
        if (newEmail != user.email) {
          await user.updateEmail(newEmail);
          await user.sendEmailVerification();
          _showSnackBar('Profile Configuration Shift Successful! Verification email dispatched.');
        } else {
          _showSnackBar('Profile Configuration Baseline committed securely!');
        }
        Navigator.of(context).pop(); 
      } catch (e) {
        _showSnackBar('Data committed to tracking profile repository, but Auth sync delayed.');
      }
    } catch (e) {
      _showSnackBar('Authentication validation rejection structural error: $e');
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Edit Profile (v$_currentVersionId)'),
        backgroundColor: const Color.fromARGB(255, 155, 33, 55),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username (3-20 Characters)', labelStyle: TextStyle(color: Colors.grey)),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio (Max 150 Characters)', labelStyle: TextStyle(color: Colors.grey)),
                style: const TextStyle(color: Colors.white),
                maxLength: 150,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.grey)),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Confirm Password to Authorize Schema Push', labelStyle: TextStyle(color: Colors.grey)),
                style: const TextStyle(color: Colors.white),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: _saveProfile,
                style: ButtonStyle(
                  minimumSize: MaterialStateProperty.all(const Size(70, 50)),
                  backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 155, 33, 55)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                ),
                child: const Text('Save Framework Configuration', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
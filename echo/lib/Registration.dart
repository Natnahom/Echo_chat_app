import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true; // State for password visibility


Future<void> register() async {
  final username = _usernameController.text.trim();
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  // 1. Schema Validation (Data types, completeness, and character limits)
  if (username.isEmpty || email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schema Violation: All fields must be populated.')),
    );
    return;
  }

  if (username.length < 3 || username.length > 20) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schema Violation: Username must be between 3 and 20 characters.')),
    );
    return;
  }

  // Check if the username already exists
  QuerySnapshot usernameSnapshot = await _firestore
      .collection('users')
      .where('username', isEqualTo: username)
      .get();

  if (usernameSnapshot.docs.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Username already exists. Please choose another.')),
    );
    return;
  }

  try {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Generate initial Configuration State Hash for Baseline tracking
    final String baselineString = "username:$username|email:$email|bio:|version:1";
    final String initialHash = sha256.convert(utf8.encode(baselineString)).toString();

    // 3. Save initial versioned Profile Document to Firestore
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'username': username,
      'email': email,
      'bio': '', // Added Bio field to match modified FR-3.3 requirement
      'profileVersionId': 1, // Start of identity baseline tracking
      'archivedHashes': [initialHash], // SCM Traceability array
    });

    Navigator.of(context).pushReplacementNamed('/login');
  } on FirebaseAuthException catch (authException) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Auth error: ${authException.message}')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration failed: ${e.toString()}')),
    );
  }
}

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Register'),
        backgroundColor: Color.fromARGB(255, 155, 33, 55),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
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
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
              style: TextStyle(color: Colors.white),
              obscureText: _obscureText,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: register,
              child: Text(
                'Register',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ButtonStyle(
                minimumSize: MaterialStateProperty.all(Size(70, 50)),
                backgroundColor: MaterialStateProperty.all(Color.fromARGB(255, 155, 33, 55)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // New button to navigate to login
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: Text(
                'Already have an account? Login here.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
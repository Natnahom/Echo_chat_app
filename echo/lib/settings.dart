import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 155, 33, 55), // Custom color
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: Text('Privacy Policy', style: TextStyle(fontSize: 18, color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
              );
            },
          ),
          ListTile(
            title: Text('Terms of Service', style: TextStyle(fontSize: 18, color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermsOfServiceScreen()),
              );
            },
          ),
          // Additional settings options...
        ],
      ),
    );
  }
}

// Privacy Policy Screen
class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 155, 33, 55), // Custom color
        title: Text('Privacy Policy'),
      ),
      body: Container(
        color: Colors.black, // Set background color to black
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy Policy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 16),
              Text(
                'Your privacy is important to us. This privacy policy explains how we collect, use, disclose, and safeguard your information when you use our application. Please read this policy carefully. If you do not agree with the terms of this privacy policy, please do not access the application.',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Information We Collect:\n- Personal Information: We may collect personal information such as your name, email address, and phone number when you register with us.\n- Usage Data: We may collect information on how the application is accessed and used.',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'How We Use Your Information:\n- To provide and maintain our service.\n- To notify you about changes to our service.\n- To allow you to participate in interactive features of our service when you choose to do so.',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Changes to This Privacy Policy:\nWe may update our privacy policy from time to time. We will notify you of any changes by posting the new privacy policy on this page.',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Terms of Service Screen
class TermsOfServiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 155, 33, 55), // Custom color
        title: Text('Terms of Service'),
      ),
      body: Container(
        color: Colors.black, // Set background color to black
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Terms of Service', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 16),
              Text(
                'Welcome to our application! These terms of service outline the rules and regulations for the use of our application. By using this application, you agree to these terms. If you do not agree with any part of these terms, you must not use our service.',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'User Responsibilities:\n- You must be at least 13 years old to use this application.\n- You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Intellectual Property:\nAll content, trademarks, and other intellectual property in the application are owned by us or our licensors. You may not reproduce, distribute, or create derivative works without our express written permission.',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Limitation of Liability:\nIn no event shall we be liable for any direct, indirect, incidental, special, consequential, or punitive damages arising from your use of the application.',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Changes to These Terms:\nWe reserve the right to modify these terms at any time. We will notify you of any changes by posting the new terms on this page.',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
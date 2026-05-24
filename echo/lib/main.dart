import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generated file with your Firebase options
import 'registration.dart'; // Your registration screen
import 'login.dart'; // Your login screen
import 'home.dart'; // Your home screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Echo',
      initialRoute: '/',
      routes: {
        '/': (context) => RegisterScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) {
          // 1. Cast as a nullable String to avoid crashing if empty
          final args = ModalRoute.of(context)!.settings.arguments as String?;
          
          // 2. Fallback to an empty string if it's null
          final userId = args ?? ''; 
          
          return HomeScreen(currentUserId: userId);
        },
      },
    );
  }
}
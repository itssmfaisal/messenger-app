import 'package:flutter/material.dart';
import 'package:messenger_app/presentation/pages/authscreen/loginscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messenger App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(), // Pointing to your new file
    );
  }
}

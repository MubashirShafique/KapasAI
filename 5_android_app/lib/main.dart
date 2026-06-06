import 'package:flutter/material.dart';
import 'SplashScreen.dart'; // SplashScreen file ko import kiya

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // App open hote hi pehle Splash Screen dikhegi
    );
  }
}

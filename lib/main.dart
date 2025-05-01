import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSplashScreenWidget(),  // This sets the HomePage fuction from home.dart as the home page of the app.
    );
  }
}

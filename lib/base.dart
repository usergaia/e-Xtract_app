import 'package:flutter/material.dart';

class Base extends StatelessWidget {
  final String title;
  final Widget child;

  const Base({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 48, 48, 48), // Common background color
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 50, 174, 59), // Common app bar color
        title: Text(title,
        style: TextStyle(
            fontSize: 24,               // Change font size
            fontWeight: FontWeight.bold, // Make text bold
            color: Color.fromARGB(255, 255, 255, 255),        // Set text color
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(child: child),
    );
  }
}
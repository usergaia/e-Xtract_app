import 'package:flutter/material.dart';
import 'select_ewaste.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'e-Xtract',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 48, 48, 48),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 50, 174, 59),
        title: const Text(
          'e-Xtract',
          style: TextStyle(
            fontSize: 24,               // Change font size
            fontWeight: FontWeight.bold, // Make text bold
            color: Color.fromARGB(255, 255, 255, 255),        // Set text color
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
            body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'e-Xtract',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Upload pictures of your e-waste or use your camera.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the e-waste selection screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SelectEwaste()),
                );
              },
              child: const Text('Get Started'),
            ),
            const SizedBox(height: 10), // Space between buttons
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'dart:io';
import 'base.dart';

class ExtractionScreen extends StatefulWidget {
  final String category;
  final String imagePath;

  const ExtractionScreen({super.key, required this.category, required this.imagePath});

  @override
  State<ExtractionScreen> createState() => _ExtractionScreenState();
}

class _ExtractionScreenState extends State<ExtractionScreen> {
  final List<String> valuableParts = ['Battery', 'Camera', 'Motherboard']; // Temporary parts list
  int currentPart = 0; // Index counter

  void nextPart() {
    setState(() {
      if (currentPart < valuableParts.length - 1) {
        currentPart++;
      }
    });
  }

  void previousPart() {
  setState(() {
    if (currentPart > 0) { 
      currentPart--;
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Base(
      title: 'Part Extraction',
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              'Valuable Parts',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 4),
              ),
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              valuableParts[currentPart], // Display the current part name
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              child: Column( // Wrap both Text widgets inside a Column
                crossAxisAlignment: CrossAxisAlignment.start, // Ensures left alignment
                children: [
                  Text(
                    'Price Estimation: ₱${valuableParts[currentPart]}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Dismantling Instructions',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10), // Adds spacing between the texts
                  Text(
                    'Steps for ${valuableParts[currentPart]}', // Correct string interpolation
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: nextPart,
              child: const Text('Next'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: previousPart,
              child: const Text('Previous'),
            )
          ],
        ),
      ),
    );
  }
}

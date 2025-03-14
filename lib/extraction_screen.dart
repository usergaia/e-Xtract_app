import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart'; // For loading JSON
import 'base.dart';

class ExtractionScreen extends StatefulWidget {
  final String category;
  final String imagePath;

  const ExtractionScreen({super.key, required this.category, required this.imagePath});

  @override
  State<ExtractionScreen> createState() => _ExtractionScreenState();
}

class _ExtractionScreenState extends State<ExtractionScreen> {
  Map<String, dynamic> ruleBase = {};
  List<String> valuableParts = ['Camera','Battery']; // Parts detected for the category
  int currentPart = 0; // Index counter

  @override
  void initState() {
    super.initState();
    loadRules();
  }

  Future<void> loadRules() async {
  String jsonString = await rootBundle.loadString('assets/knowledge-base.json');
  Map<String, dynamic> data = json.decode(jsonString);

  print("Widget Category: ${widget.category}");
  print("JSON Categories: ${data.keys}");

  if (data.containsKey(widget.category)) {
    setState(() {
      ruleBase = data[widget.category];
      valuableParts = ruleBase.keys.toList();
    });
  } else {
    print("Category not found in JSON!");
  }
}

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
    String partName = valuableParts.isNotEmpty ? valuableParts[currentPart] : "Loading...";
    Map<String, dynamic>? partDetails = ruleBase[partName];

    return Base(
      title: 'Part Extraction',
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              'Valuable Parts',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 4)),
              child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
            ),
            const SizedBox(height: 10),
            Text(
              partName, // Display the current part name
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price Estimation: ${partDetails?["value"] ?? "N/A"}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Dismantling Instructions:',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  for (var step in partDetails?["extraction_steps"] ?? []) 
                    Text("- $step", style: const TextStyle(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(
                    'Hazards:',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(partDetails?["hazards"]?.join("\n") ?? "N/A", style: const TextStyle(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(
                    'Recycling Info:',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(partDetails?["recycling_info"] ?? "N/A", style: const TextStyle(fontSize: 18, color: Colors.white)),
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

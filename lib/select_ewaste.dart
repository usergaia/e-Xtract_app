import 'package:extract_app/smartphone_selection.dart';
import 'package:extract_app/laptop_selection.dart';
import 'package:extract_app/desktop_selection.dart';
import 'package:extract_app/router_selection.dart';
import 'package:extract_app/landline_selection.dart';
import 'package:flutter/material.dart';
import 'base.dart';

class SelectEwaste extends StatelessWidget { // Class names should be PascalCase
  const SelectEwaste({super.key});

  @override
  Widget build(BuildContext context) {
    return Base(
      title: 'Select E-Waste Type', // Uses the title from Base
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildEwasteButton(context, 'Smartphone'),
          _buildEwasteButton(context, 'Laptop'),
          _buildEwasteButton(context, 'Desktop'),
          _buildEwasteButton(context, 'Router'),
          _buildEwasteButton(context, 'Landline Phone'),
        ],
      ),
    );
  }

  // Create e-waste buttons
  Widget _buildEwasteButton(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // Button color
          minimumSize: const Size(double.infinity, 50), // Full width
        ),
        onPressed: () {
          if (label == 'Smartphone') {
            Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SmartphoneSelection()),
                );
          } else if (label == 'Laptop') {
            Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LaptopSelection()),
                );
          } else if (label == 'Desktop') {
            Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DesktopSelection()),
                );
          }
           else if (label == 'Router') {
            Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RouterSelection()),
                );
          }
          else if (label == 'Landline Phone') {
            Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LandlineSelection()),
                );
          }
        },
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, color: Color.fromARGB(255, 48, 48, 48)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'base.dart'; // Keep Base
import 'laptop_extraction.dart'; // Import extraction screen

class LaptopSelection extends StatefulWidget {
  const LaptopSelection({super.key});

  @override
  State<LaptopSelection> createState() => _LaptopSelectionState();
}

class _LaptopSelectionState extends State<LaptopSelection> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      // Navigate to extraction screen and pass the image path
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LaptopExtraction(imagePath: image.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      title: 'Laptop', // Keep Base title
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Upload a picture of your e-waste or use your camera',
            style: TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            child: const Text('Upload Image'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _pickImage(ImageSource.camera),
            child: const Text('Use Camera'),
          ),
        ],
      ),
    );
  }
}

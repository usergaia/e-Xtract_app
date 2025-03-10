import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Required for File
import 'base.dart';
import 'extraction_screen.dart';

class UploadOrCamera extends StatefulWidget {
  final String category;

  const UploadOrCamera({super.key, required this.category});

  @override
  State<UploadOrCamera> createState() => _UploadOrCameraState();
}

class _UploadOrCameraState extends State<UploadOrCamera> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath; // Stores the selected image path

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _imagePath = image.path; // Update the UI to show the image
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      title: widget.category,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Upload a picture of your e-waste or use your camera',
            style: TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Show the image if one has been selected
          if (_imagePath != null)
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 4),
              ),
              child: Image.file(
                File(_imagePath!),
                fit: BoxFit.cover,
              ),
            ),

          const SizedBox(height: 20),

          // Buttons for image selection
          ElevatedButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            child: const Text('Upload Image'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _pickImage(ImageSource.camera),
            child: const Text('Use Camera'),
          ),

          // "Proceed to Extraction" button only appears if an image is selected
          if (_imagePath != null) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExtractionScreen(
                      category: widget.category,
                      imagePath: _imagePath!,
                    ),
                  ),
                );
              },
              child: const Text('Proceed to Extraction'),
            ),
          ],
        ],
      ),
    );
  }
}

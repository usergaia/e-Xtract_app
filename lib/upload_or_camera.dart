import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io'; 
import 'base.dart';
import 'extraction_screen.dart';
import 'test_model.dart';

class UploadOrCamera extends StatefulWidget {
  final String category;

  const UploadOrCamera({super.key, required this.category});

  @override
  State<UploadOrCamera> createState() => _UploadOrCameraState();
}

class _UploadOrCameraState extends State<UploadOrCamera> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath; 

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _imagePath = image.path; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      title: widget.category,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              'Upload a picture of your e-waste or use your camera.',
              style: GoogleFonts.robotoCondensed(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
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

            _buildUploadCameraButton(context, 'Upload Image', Icons.upload),
            const SizedBox(height: 10),
            _buildUploadCameraButton(context, 'Use Camera', Icons.camera_alt),

            if (_imagePath != null) ...[
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestModelScreen(
                        //category: widget.category,
                        //imagePath: _imagePath!,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 50, 174, 59),
                ),
                child: Text('Proceed to Extraction',
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Create a reusable widget for the upload or camera buttons
  Widget _buildUploadCameraButton(BuildContext context, String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (label == 'Upload Image') {
          _pickImage(ImageSource.gallery); 
        } else if (label == 'Use Camera') {
          _pickImage(ImageSource.camera); 
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF34A853), Color(0xFF0F9D58)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 4),
             blurRadius: 10,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20), 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

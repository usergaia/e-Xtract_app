import 'package:extract_app/part_detection.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:extract_app/chatbot_screen.dart';
import 'dart:io';
import 'base.dart';

class UploadOrCamera extends StatefulWidget {
  final String category;

  const UploadOrCamera({super.key, required this.category});

  @override
  State<UploadOrCamera> createState() => _UploadOrCameraState();
}

class _UploadOrCameraState extends State<UploadOrCamera> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  Future<void> _pickMultipleImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _pickSingleImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      title: widget.category,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 50),
            Text(
              'Upload pictures of your e-waste or use your camera.',
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 300,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 200,
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 4),
                          ),
                          child: ClipRRect(
                            child: Image.file(
                              File(_selectedImages[index].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            _buildUploadCameraButton(context, 'Upload Image', Icons.upload),
            const SizedBox(height: 10),
            _buildUploadCameraButton(context, 'Use Camera', Icons.camera_alt),

            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  List<Map<String, dynamic>> results = [];

                  for (var image in _selectedImages) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PartDetectionScreen(
                          category: widget.category,
                          imagePath: image.path,
                        ),
                      ),
                    );

                    if (result != null) {
                      results.add({
                        'imagePath': image.path,
                        'detectedComponents': result['detectedComponents'] ?? [],
                        'croppedComponentImages': result['croppedComponentImages'] ?? {},
                      });
                    }
                  }

                  if (results.isNotEmpty) {
                    // Prepare data for ChatbotScreen
                    final List<String> imagePaths = results.map((result) => result['imagePath'] as String).toList();
                    final Map<String, List<String>> detectedPartsPerImage = {
                      for (var result in results)
                        result['imagePath']: List<String>.from(result['detectedComponents']),
                    };
                    final Map<String, Map<String, String>> componentImagesPerImage = {
                      for (var result in results)
                        result['imagePath']: Map<String, String>.from(result['croppedComponentImages']),
                    };

                    // Assign each image an index for batch tracking
                    final List<int> initialBatch = List.generate(imagePaths.length, (i) => i);

                    // Pass all images and their data to ChatbotScreen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatbotScreen(
                          initialCategory: widget.category,
                          initialImagePath: null, // No single initial image
                          initialDetections: [], // No single initial detections
                          initialComponentImages: componentImagesPerImage, // Pass all component images
                          initialBatch: initialBatch, // Pass batch
                        ),
                      ),
                    );

                    // Prepare the full data and preserve index batch mapping

                    // Ensure all images are initialized in ChatbotScreen
                    for (var imagePath in imagePaths) {
                      if (imagePath != imagePaths.first) {
                        detectedPartsPerImage[imagePath] ??= [];
                        componentImagesPerImage[imagePath] ??= {};
                      }
                    }
                  } else {
                    // Show an error message if no results were processed
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No images were processed. Please try again.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ).copyWith(
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  backgroundColor: MaterialStateProperty.all(
                    Colors.transparent,
                  ),
                ),
                child: Ink(
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    child: Text(
                      'Continue',
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCameraButton(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        if (label == 'Upload Image') {
          _pickMultipleImages();
        } else if (label == 'Use Camera') {
          _pickSingleImage(ImageSource.camera);
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
            Icon(icon, color: Colors.white, size: 40),
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
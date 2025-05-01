import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '/pages/assistant.dart';
import '/pages/base.dart';

// Define a stateful widget class for the Detection Page
// StatefulWidget means this UI component can change its appearance based on state changes
class DetectionPage extends StatefulWidget {
  // Define required parameters that must be provided when creating this widget
  final String category; // The category of device being analyzed (e.g., 'Desktop')
  final List<File> selectedImages; // List of image files selected by the user
  final String sessionId;

  // Constructor that requires both parameters
  // Key is an identifier that Flutter uses to preserve state when widgets are rebuilt
  const DetectionPage({
    Key? key, // '?' means this parameter is optional
    required this.category, // 'required' keyword means this parameter must be provided
    required this.selectedImages,
    required this.sessionId,
  }) : super(key: key); // Pass the key to the parent StatefulWidget class

  @override
  // This is where all the changing data and UI logic will be stored
  _DetectionPageState createState() => _DetectionPageState();
}

// The state class that contains all the logic and UI building for the DetectionPage
// SingleTickerProviderStateMixin enables this class to act as a ticker for animations
class _DetectionPageState extends State<DetectionPage> with SingleTickerProviderStateMixin {
  // Declare variables to manage the TensorFlow Lite model
  late Interpreter _interpreter; // 'late' means this variable will be initialized before use but not immediately
                                // 'Interpreter' is a class from the tflite_flutter package that loads and runs the ML model
  bool _isModelLoaded = false; // Track if the ML model is loaded
  List<String> _labels = []; // Store class labels for detection (e.g., 'gpu', 'ram', etc.)
  
  // Lists to store detection results for each image
  List<List<Detection>> _allDetections = []; // Outer list are the images. Inner list are the detections for each image
  List<Map<String, String>> _allCroppedComponents = []; // Store paths to cropped component images
  
  // Track the current image being processed/viewed
  int _currentImageIndex = 0; // Index of the current image being shown
 
  // PageController manages swipe navigation between multiple images
  late PageController _pageController; // later means it will initialized later.
  
  // GlobalKey objects are used to access widget information in the render tree
  // Here they're used to capture images with bounding boxes drawn on them
  List<GlobalKey> _imageWithBoxesKeys = [];
  
  // Animation controller for loading indicator (spinner)
  late AnimationController _animationController;

  // Track processing status for each image (true when an image is being processed)
  List<bool> _processingStatus = [];

  @override
  void initState() {
    // initState is called when the widget is first inserted into the widget tree
    super.initState(); // Call parent's initState method
    
    // Initialize animation controller for loading spinner
    // 'this' provides the ticker needed for animation
    _animationController = AnimationController(
      vsync: this, // The ticker provider (this class with the mixin)
      duration: const Duration(seconds: 5), // Animation completes in 2 seconds
    )..repeat(); // '..' is a cascade operator that calls repeat() on the same object
    
    // Initialize page controller starting at the first image (index 0)
    _pageController = PageController(initialPage: 0);
    
    // Create GlobalKey for each image to capture rendered output
    _imageWithBoxesKeys = List.generate(
      widget.selectedImages.length, // Create as many keys as there are images
      (index) => GlobalKey(), // Each key is a new GlobalKey
    );
    
    // Initialize empty lists for detection results
    // Each list will have one entry per image
    _allDetections = List.generate(
      widget.selectedImages.length,
      (index) => [], // Each image starts with an empty detection list
    );
    
    
    // Initialize empty maps for cropped component images
    _allCroppedComponents = List.generate(
      widget.selectedImages.length,
      (index) => {}, // Empty map for each image
    );

    // Initialize processing status for each image (all false initially)
    _processingStatus = List.generate(
      widget.selectedImages.length,
      (index) => false, // No images are being processed initially
    );
    
    // Load ML model and labels, then process the first image
    // '.then' executes the function when the Future completes
    _loadModelAndLabels().then((_) { // The underscore inside the parenthesis is a placeholder for the value returned by the Future.
      _processNextImage(); // Start processing the first image after model is loaded
    });
  }

  @override
  void dispose() {
    // dispose is called when this widget is removed from the widget tree
    _animationController.dispose(); // Clean up animation controller to prevent memory leaks
    _pageController.dispose(); // Clean up page controller
    if (_isModelLoaded) {
      _interpreter.close(); // Release TensorFlow Lite resources
    }
    super.dispose(); // Call parent's dispose method
  }

  // Loads the TensorFlow model and label files based on device category
  Future<void> _loadModelAndLabels() async {
    // 'async' means this function returns a Future and can use 'await'
    try {
      // Try to load the model and handle any errors
      String modelPath = _getModelPathBasedOnCategory(widget.category);
      // Load the TensorFlow model from app assets
      _interpreter = await Interpreter.fromAsset(modelPath); // 'await' pauses execution until this completes
      
      // Load labels (class names) for the model
      await _loadLabels();
      
      // Update the UI state to indicate model is loaded
      setState(() { // setState triggers a rebuild of the UI with new state
        _isModelLoaded = true;
      });
      
      // Log success and model information
      print("Model loaded successfully");
      print("Input shape: ${_interpreter.getInputTensor(0).shape}");
      print("Output shape: ${_interpreter.getOutputTensor(0).shape}");
    } catch (e) {
      // Handle any errors that occur during model loading
      print("Failed to load model: $e");
    }
  }

  // Load label names from text file based on device category
  Future<void> _loadLabels() async {
    try {
      // Read label file content from app assets
      final labelData = await rootBundle.loadString(
        _getLabelPathBasedOnCategory(widget.category),
      );
      // Parse labels and update state
      setState(() {
        _labels = labelData.split('\n') // Split by newline
            .map((label) => label.trim()) // Remove whitespace
            .where((label) => label.isNotEmpty) // Filter out empty labels
            .toList();
      });
      print("Labels loaded: ${_labels.length}");
    } catch (e) {
      print("Failed to load labels: $e");
    }
  }

  // Process images one by one to avoid overloading the device
  Future<void> _processNextImage() async {
    // Check if all images have been processed
    if (_currentImageIndex >= widget.selectedImages.length) {
      return; // Exit if all images are processed
    }

    // Mark the current image as being processed
    setState(() {
      _processingStatus[_currentImageIndex] = true;
    });

    try {
      // Process the current image
      await _processImage(widget.selectedImages[_currentImageIndex], _currentImageIndex);
    } finally {
      // Always mark processing as complete, even if errors occurred
      setState(() {
        _processingStatus[_currentImageIndex] = false;
      });

      // Move to the next image if there are more
      _currentImageIndex++;
      if (_currentImageIndex < widget.selectedImages.length) {
        _processNextImage(); // Process the next image recursively
      } else {
        // Reset to first image after processing all
        setState(() {
          _currentImageIndex = 0;
        });
      }
    }
  }

  // Process a single image with the ML model
  Future<void> _processImage(File imageFile, int imageIndex) async {
    try {
      print("Processing image ${imageIndex + 1} of ${widget.selectedImages.length}");
      
      // Read image file into memory
      final rawBytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(rawBytes); // Parse bytes as image
      if (decoded == null) {
        print("Failed to decode image.");
        return;
      }
      
      // Allow UI to update by yielding to the event loop
      await Future.delayed(Duration.zero);
      
      // Resize image to 1280x1280 (model input size)
      final resized = img.copyResize(decoded, width: 1280, height: 1280);
      // Create a Float32List (optimized for ML) to hold normalized pixel data
      final inputImage = Float32List(1280 * 1280 * 3); // 3 channels (RGB)
      
      // Process each pixel in chunks to avoid freezing UI
      int index = 0;
      for (int y = 0; y < 1280; y++) {
        for (int x = 0; x < 1280; x++) {
          // Get pixel color at current position
          final p = resized.getPixel(x, y);
          // Convert RGB values to normalized float (0-1)
          inputImage[index++] = p.r / 255.0; // Red channel
          inputImage[index++] = p.g / 255.0; // Green channel
          inputImage[index++] = p.b / 255.0; // Blue channel
        }
        
        // Periodically yield to UI thread to keep app responsive
        if (y % 128 == 0) {
          await Future.delayed(Duration.zero);
        }
      }
      
      // Prepare tensors for model input and output
      // Reshape input to match model's expected format [batch, height, width, channels]
      final input = inputImage.reshape([1, 1280, 1280, 3]);
      // Get model output shape to create appropriately sized output buffer
      final outputShape = _interpreter.getOutputTensor(0).shape;
      // Create nested lists for output data with correct dimensions
      final output = List.generate(
        outputShape[0], // Batch size
        (_) => List.generate(
          outputShape[1], // Number of detections
          (_) => List.filled(outputShape[2], 0.0), // Values per detection
        ),
      );
      
      // Run model inference
      _interpreter.run(input, output);
      
      // Process detection results
      _parseAndStoreDetections(output[0], imageIndex);
      
    } catch (e) {
      print("Error processing image: $e");
    }
  }

  // Parse model output and convert to Detection objects
  void _parseAndStoreDetections(
    List<List<double>> detections,
    int imageIndex, {
    double threshold = 0.25, // Confidence threshold (ignore detections below this)
  }) {
    List<Detection> dets = []; // Temporary list to store detections

    // Process each detection from the model output
    for (int i = 0; i < detections[0].length; i++) {
      // Extract this detection's values from nested lists
      final pred = List.generate(detections.length, (j) => detections[j][i]);
      if (pred.length < 5) continue; // Skip if not enough data
      
      // Extract bounding box center coordinates and dimensions
      final cx = pred[0]; // Center X (normalized 0-1)
      final cy = pred[1]; // Center Y (normalized 0-1)
      final w = pred[2];  // Width (normalized 0-1)
      final h = pred[3];  // Height (normalized 0-1)
      
      // Convert center format to top-left format
      final x = cx - w / 2; // Top-left X
      final y = cy - h / 2; // Top-left Y
      
      // Get class scores (confidence values for each class)
      final scores = pred.sublist(4); // All values after the first 4 are class scores
      // Find highest confidence score and its index
      final maxScore = scores.reduce((a, b) => a > b ? a : b);
      final clsIdx = scores.indexOf(maxScore);
      
      // Skip detections with low confidence
      if (maxScore < threshold) continue;
      
      // Get class name from labels list
      final name = (clsIdx < _labels.length) ? _labels[clsIdx] : 'Unknown';

      // Skip unwanted components
      if (!_shouldIncludeComponent(name)) continue;

      // Create Detection object and add to list
      dets.add(
        Detection(
          score: maxScore, // Confidence score
          boundingBox: Rect(x: x, y: y, width: w, height: h), // Bounding box
          className: name, // Class name
        ),
      );
    }
    
    // Apply Non-Maximum Suppression to remove overlapping boxes
    final filteredDetections = _applyNMS(dets, 0.4);
    
    // Sort detections by confidence (highest first)
    filteredDetections.sort((a, b) => b.score.compareTo(a.score));
    
    // Log detection results
    print("DETECTED PARTS FOR IMAGE $imageIndex:");
    for (var det in filteredDetections) {
      print("  - ${det.className} (${(det.score * 100).toStringAsFixed(1)}%)");
    }
    
    // Update state with new detections to trigger UI update
    setState(() {
      _allDetections[imageIndex] = filteredDetections;
    });
  }

  // Apply Non-Maximum Suppression to remove overlapping bounding boxes
  List<Detection> _applyNMS(List<Detection> dets, double iouThreshold) {
    // Sort detections by score (highest first)
    dets.sort((a, b) => b.score.compareTo(a.score));
    List<Detection> kept = []; // List of boxes to keep
    
    // Process each detection in order of confidence
    while (dets.isNotEmpty) {
      final cur = dets.removeAt(0); // Take the highest confidence detection
      // Remove any remaining detections that overlap too much with current one
      dets.removeWhere((d) => _calculateIoU(cur.boundingBox, d.boundingBox) > iouThreshold);
      kept.add(cur); // Keep the current detection
    }
    
    return kept; // Return filtered list
  }

  // Calculate Intersection over Union between two bounding boxes
  // This measures how much two boxes overlap
  double _calculateIoU(Rect box1, Rect box2) {
    // Calculate the intersection rectangle coordinates
    final intersectionX = (box1.x + box1.width).clamp(box2.x, box2.x + box2.width) - 
                         box1.x.clamp(box2.x, box2.x + box2.width);
    final intersectionY = (box1.y + box1.height).clamp(box2.y, box2.y + box2.height) - 
                         box1.y.clamp(box2.y, box2.y + box2.height);
    
    // If boxes don't intersect, IoU is 0
    if (intersectionX < 0 || intersectionY < 0) return 0;
    
    // Calculate areas
    final intersectionArea = intersectionX * intersectionY;
    final box1Area = box1.width * box1.height;
    final box2Area = box2.width * box2.height;
    // IoU = intersection area / union area
    final unionArea = box1Area + box2Area - intersectionArea;
    
    return intersectionArea / unionArea;
  }

  // Get model file path based on device category
  String _getModelPathBasedOnCategory(String category) {
    switch (category) {
      case 'Smartphone':
        return 'assets/models/smartphone/best_phone_float16.tflite';
      case 'Laptop':
        return 'assets/models/laptop/best_laptop_float16.tflite';
      case 'Desktop':
        return 'assets/models/computer/best_computer_float16.tflite';
      case 'Router':
      case 'Landline':
        return 'assets/models/telecom/best_router-1_float16.tflite';
      default:
        // Throw exception if category is unknown
        throw Exception("Model not found for category: $category");
    }
  }

  // Get label file path based on device category
  String _getLabelPathBasedOnCategory(String category) {
    switch (category) {
      case 'Smartphone':
        return 'assets/models/smartphone/labels.txt';
      case 'Laptop':
        return 'assets/models/laptop/labels.txt';
      case 'Desktop':
        return 'assets/models/computer/labels.txt';
      case 'Router':
      case 'Landline':
        return 'assets/models/telecom/labels.txt';
      default:
        throw Exception("Label file not found for category: $category");
    }
  }


  // Crop all detected components from the original image
  Future<Map<String, String>> _cropAllDetectedComponents(
    String imagePath,
    List<Detection> detections,
  ) async {
    Map<String, String> componentImages = {}; // Map to store component name -> image path

    // Process each detection
    for (var detection in detections) {
      // Skip unwanted components
      if (!_shouldIncludeComponent(detection.className)) continue;

      // Crop this component from the original image
      final componentPath = await _cropComponentImage(
        imagePath,
        detection.boundingBox,
        detection.className,
      );

      if (componentPath.isNotEmpty) {
        // Handle duplicate component names by adding a counter
        String key = detection.className;
        int counter = 1;
        while (componentImages.containsKey(key)) {
          key = "${detection.className}_$counter"; // Add suffix for duplicates
          counter++;
        }
        componentImages[key] = componentPath; // Store path in map
      }
    }

    return componentImages;
  }

  // Crop a single component from the original image
  Future<String> _cropComponentImage(
    String imagePath,
    Rect boundingBox,
    String componentName,
  ) async {
    try {
      // Read the original image
      final rawBytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(rawBytes);
      
      if (decoded == null) return "";
      
      // Calculate crop dimensions
      final imageWidth = decoded.width.toDouble();
      final imageHeight = decoded.height.toDouble();
      
      // Add padding around component (10% of size)
      int padX = (boundingBox.width * imageWidth * 0.1).round();
      int padY = (boundingBox.height * imageHeight * 0.1).round();
      
      // Calculate crop coordinates, ensuring they're within image bounds
      int x = (boundingBox.x * imageWidth - padX).round().clamp(0, decoded.width - 1);
      int y = (boundingBox.y * imageHeight - padY).round().clamp(0, decoded.height - 1);
      int width = (boundingBox.width * imageWidth + padX * 2).round().clamp(1, decoded.width - x);
      int height = (boundingBox.height * imageHeight + padY * 2).round().clamp(1, decoded.height - y);
      
      // Crop the image
      final cropped = img.copyCrop(
        decoded,
        x: x,
        y: y,
        width: width,
        height: height,
      );
      
      // Save cropped image to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = componentName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_'); // Remove special chars
      final path = '${tempDir.path}/component_${sanitizedName}_$timestamp.jpg';
      
      // Write JPEG file
      final file = File(path);
      await file.writeAsBytes(img.encodeJpg(cropped, quality: 90));
      
      return path; // Return the path to the cropped image
    } catch (e) {
      print("Error cropping component: $e");
      return ""; // Return empty string on failure
    }
  }

  // Format class name for display (convert 'ram_module' to 'Ram Module')
  String _formatClassName(String rawName) {
    return rawName
        .split('_') // Split by underscore
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)) // Capitalize
        .join(' '); // Join with spaces
  }

  // Filters Antenna from Landline and Speaker from Router since they share the same TFlite model
  bool _shouldIncludeComponent(String componentName) {
    // Return false for components that should be excluded based on category
    if ((widget.category == 'Landline' && componentName == 'antenna') ||
        (widget.category == 'Router' && componentName == 'Speaker')) {
      return false; // Exclude unwanted components
    }
    return true; // Include all other components
  }

  @override
  // Build the UI for this screen
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Base( // Using the Base widget instead of Scaffold
      title: 'Detection Results', // Title for the app bar
      child: SafeArea(
        // SafeArea avoids system UI elements like notches and status bars
        child: Padding(
          // Add padding around content
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04, // 4% of screen width
            vertical: screenHeight * 0.02, // 2% of screen height
          ),
          child: Column(
            // Column arranges children vertically
            children: [
              // Image container with detection boxes
              RepaintBoundary(
                // RepaintBoundary optimizes rendering and allows capturing as image
                key: _currentImageIndex < widget.selectedImages.length 
                    ? _imageWithBoxesKeys[_currentImageIndex] // Use specific key for current image
                    : GlobalKey(), // Fallback key
                child: Container(
                  // Container for the image
                  width: double.infinity, // Full width
                  height: screenHeight * 0.3, // 30% of screen height
                  decoration: BoxDecoration(
                    // Container styling
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5), // Shadow offset
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge, // Clip content to container bounds
                  child: PageView.builder(
                    // PageView allows swiping between pages (images)
                    controller: _pageController,
                    itemCount: widget.selectedImages.length, // Number of pages
                    onPageChanged: (index) {
                      // Called when page is swiped
                      print("PAGE CHANGED TO: $index");
                      setState(() {
                        _currentImageIndex = index; // Update current image index
                      });
                    },
                    itemBuilder: (context, index) {
                      // Build each page
                      return Stack(
                        // Stack allows placing widgets on top of each other
                        fit: StackFit.expand, // Expand to fill container
                        children: [
                          // Base image
                          Image.file(
                            widget.selectedImages[index], // Display image from file
                            fit: BoxFit.contain, // Scale image to fit
                          ),
                          
                          // Bounding boxes overlay
                          _processingStatus[index]
                              ? const Center(
                                  // Show loading indicator when processing
                                  child: CircularProgressIndicator(
                                    color: Colors.greenAccent,
                                  ),
                                )
                              : _buildBoundingBoxes(index), // Show bounding boxes when ready
                              
                          // Image counter indicator
                          Positioned(
                            // Position at top-right
                            top: 8,
                            right: 8,
                            child: Container(
                              // Counter container
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${index + 1}/${widget.selectedImages.length}', // "1/3", "2/3", etc.
                                style: GoogleFonts.robotoCondensed(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.024), // Spacing (2.4% of screen height)
              
              // Detected Parts Title
              Text(
                'Detected Parts',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: screenHeight * 0.03,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12), // Fixed 12 pixel spacing
              
              // Detected Parts List (scrollable)
              Expanded(
                // Expanded makes this widget take all available vertical space
                child: _buildDetectedPartsList(), // Custom method to build the list
              ),
              
              // Continue button
              GestureDetector(
                onTap: (_processingStatus.contains(true) || 
                        _allDetections[_currentImageIndex].isEmpty) 
                    ? null 
                    : () async {
                        // Don't proceed if still processing
                        if (_processingStatus.contains(true)) return;

                        // Prepare data for chatbot
                        List<String> allDetectedComponents = []; // All component names
                        Map<String, Map<String, String>> allComponentImages = {}; // Component images by image
                        
                        for (int i = 0; i < widget.selectedImages.length; i++) {
                          if (_allDetections[i].isNotEmpty) {
                            // Collect all detected component names from this image
                            allDetectedComponents.addAll(
                              _allDetections[i]
                                .where((detection) => _shouldIncludeComponent(detection.className))
                                .map((det) => det.className)
                            );

                            // Always use original images, not processed ones
                            final String imagePath = widget.selectedImages[i].path;

                            // Generate component crops on demand if needed
                            if (_allCroppedComponents[i].isEmpty && _allDetections[i].isNotEmpty) {
                              _allCroppedComponents[i] = await _cropAllDetectedComponents(
                                widget.selectedImages[i].path,
                                _allDetections[i],
                              );
                            }

                            // Store this image's cropped components
                            allComponentImages[imagePath] = _allCroppedComponents[i];
                          }
                        }

                        // Filter out unwanted components based on category
                        allDetectedComponents = allDetectedComponents
                            .where((component) => _shouldIncludeComponent(component))
                            .toList();

                        // Navigate to ChatbotRedo page with detection results
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatbotRedo(
                              // Pass data to ChatbotRedo
                              initialCategory: widget.category,
                              initialImagePath: widget.selectedImages.isNotEmpty 
                                  ? widget.selectedImages[0].path
                                  : null,
                              initialDetections: allDetectedComponents,
                              initialComponentImages: allComponentImages,
                              initialBatch: List<int>.generate(
                                widget.selectedImages.length, 
                                (index) => index
                              ),
                            ),
                          ),
                        );
                      },
                child: Container(
                  // Continue button styling
                  width: double.infinity, // Full width
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018), // Vertical padding
                  margin: const EdgeInsets.only(top: 16), // Margin at top
                  decoration: BoxDecoration(
                    // Button styling with conditional colors
                    gradient: LinearGradient(
                      colors: (_processingStatus.contains(true) || 
                              (_currentImageIndex < _allDetections.length && 
                               _allDetections[_currentImageIndex].isEmpty))
                          ? [Colors.grey.shade700, Colors.grey.shade600] // Grayed out when disabled
                          : [Color(0xFF34A853), Color(0xFF0F9D58)],      // Green when enabled
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    // Center text in button
                    child: Text(
                      'Continue',
                      style: GoogleFonts.montserrat(
                        fontSize: screenHeight * 0.02,
                        fontWeight: FontWeight.bold,
                        color: (_processingStatus.contains(true) || 
                               (_currentImageIndex < _allDetections.length && 
                                _allDetections[_currentImageIndex].isEmpty))
                            ? Colors.grey.shade300
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build bounding boxes for an image
  Widget _buildBoundingBoxes(int imageIndex) {
    // If no detections for this image, return empty container
    if (imageIndex >= _allDetections.length || _allDetections[imageIndex].isEmpty) {
      return Container(); // No detections to show
    }

    // LayoutBuilder provides the parent widget constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get container dimensions
        final imageWidth = constraints.maxWidth;
        final imageHeight = constraints.maxHeight;

        // Create a stack of positioned bounding boxes
        return Stack(
          children: _allDetections[imageIndex]
              .where((detection) => _shouldIncludeComponent(detection.className))
              .map((detection) {
                // Calculate pixel coordinates from normalized values (0-1)
                final left = detection.boundingBox.x * imageWidth;
                final top = detection.boundingBox.y * imageHeight;
                final width = detection.boundingBox.width * imageWidth;
                final height = detection.boundingBox.height * imageHeight;

                // Position the bounding box
                return Positioned(
                  left: left,
                  top: top,
                  width: width,
                  height: height,
                  child: Container(
                    // Bounding box styling
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 2), // Green border
                      borderRadius: BorderRadius.circular(4), // Slightly rounded corners
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        // Label box at top-left of bounding box
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8),
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(4), // Round only bottom-right corner
                          ),
                        ),
                        child: Text(
                          // Show component name and confidence percentage
                          '${_formatClassName(detection.className)} ${(detection.score * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis, // Truncate with ... if too long
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(),
        );
      },
    );
  }
  
  // Build the detected parts list
  Widget _buildDetectedPartsList() {
    // If image is still processing, show loading indicator
    if (_processingStatus[_currentImageIndex]) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Take only needed vertical space
          children: [
            // Rotating progress indicator
            RotationTransition(
              turns: _animationController, // Animation controller provides rotation
              child: const CircularProgressIndicator(color: Colors.greenAccent),
            ),
            const SizedBox(height: 16),
            Text(
              'Analyzing image...',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }
    
    // If no detections for current image, show message
    if (_currentImageIndex >= _allDetections.length || 
        _allDetections[_currentImageIndex].isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No components detected.',
              style: GoogleFonts.robotoCondensed(
                fontSize: MediaQuery.of(context).size.height * 0.022,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.018),
            Text(
              'Please try again with a clearer image or different angle.',
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoCondensed(
                fontSize: MediaQuery.of(context).size.height * 0.018,
                color: Colors.white60,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.024),
            GestureDetector(
              onTap: () {
                // Navigate back to UploadOrCamera screen
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.1,
                  vertical: MediaQuery.of(context).size.height * 0.014,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.redAccent, Colors.red],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  'Try Another Image',
                  style: GoogleFonts.montserrat(
                    fontSize: MediaQuery.of(context).size.height * 0.018,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Build a scrollable list of detected components
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: _allDetections[_currentImageIndex]
          .where((detection) => _shouldIncludeComponent(detection.className))
          .toList()
          .length,
      itemBuilder: (context, index) {
        final filteredDetections = _allDetections[_currentImageIndex]
            .where((detection) => _shouldIncludeComponent(detection.className))
            .toList();

        final detection = filteredDetections[index];

        return Card(
          // Card for each component
          color: Colors.white10, // Slight white tint on dark background
          margin: const EdgeInsets.only(bottom: 8), // Space between cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          child: ListTile(
            // ListTile provides standard layout for items in a list
            leading: CircleAvatar(
              // Numbered circle on left
              backgroundColor: const Color(0xFF1E1E1E),
              child: Text(
                '${index + 1}', // Component number (1-based)
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              // Component name
              _formatClassName(detection.className),
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            trailing: Text(
              // Confidence percentage on right
              '${(detection.score * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.robotoCondensed(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Detection class to store detection results
class Detection {
  final double score; // Confidence score (0-1)
  final Rect boundingBox; // Rectangle coordinates
  final String className; // Component name (e.g., 'gpu', 'ram')
  
  // Constructor requires all fields
  Detection({
    required this.score,
    required this.boundingBox,
    required this.className,
  });
}

// Rectangle class for bounding boxes
class Rect {
  final double x, y, width, height; // All values normalized (0-1)
  
  // Constructor requires all dimensions
  Rect({
    required this.x, // Left coordinate
    required this.y, // Top coordinate
    required this.width, // Width
    required this.height, // Height
  });
}
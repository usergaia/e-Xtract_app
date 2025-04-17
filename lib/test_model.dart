import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';

class PartDetectionScreen extends StatefulWidget {
  final String category;
  final String imagePath;

  const PartDetectionScreen({
    super.key,
    required this.category,
    required this.imagePath,
  });

  @override
  State<PartDetectionScreen> createState() => _PartDetectionScreenState();
}

class _PartDetectionScreenState extends State<PartDetectionScreen> {
  late Interpreter _interpreter;
  late File _image;
  bool _isProcessing = false;
  bool _isModelLoaded = false;
  List<String> _labels = [];
  List<Detection> _finalDetections = [];

  @override
  void initState() {
    super.initState();
    _image = File(widget.imagePath); // set image first
    _loadModelAndProcessImage();     // handles model loading + inference
  }

  Future<void> _loadModelAndProcessImage() async {
    if (!_isModelLoaded) {
      await _loadModel();
    }
    if (_isModelLoaded) {
      await _loadLabels(); // Load labels after model is loaded
      setState(() => _isProcessing = true);
      await _processImage(_image);
    }
  }

  Future<void> _loadLabels() async {
    final labelData = await rootBundle.loadString(_getLabelPathBasedOnCategory(widget.category));
    setState(() {
      _labels = labelData.split('\n').map((label) => label.trim()).toList();
    });
  }

  Future<void> _loadModel() async {
    try {
      print("Loading model...");
      String modelPath = _getModelPathBasedOnCategory(widget.category);
      _interpreter = await Interpreter.fromAsset(modelPath);
      setState(() {
        _isModelLoaded = true;
      });
      print("Model loaded successfully.");
      print("Input shape: ${_interpreter.getInputTensor(0).shape}");
      print("Output shape: ${_interpreter.getOutputTensor(0).shape}");
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  // Get model path based on category
  String _getModelPathBasedOnCategory(String category) {
    switch (category) {
      case 'Smartphone':
        return 'assets/models/smartphone/best_phone.tflite';
      case 'Laptop':
        return 'assets/models/laptop/best_laptop.tflite';
      case 'Desktop':
        return 'assets/models/computer/best_computer.tflite';
      case 'Router':
      case 'Landline Phone':
        return 'assets/models/telecom/best_telecom.tflite';
      default:
        throw Exception("Model not found for category: $category");
    }
  }

  // Get label path based on category
  String _getLabelPathBasedOnCategory(String category) {
    switch (category) {
      case 'Smartphone':
        return 'assets/models/smartphone/labels.txt';
      case 'Laptop':
        return 'assets/models/laptop/labels.txt';
      case 'Desktop':
        return 'assets/models/computer/labels.txt';
      case 'Router':
      case 'Landline Phone':
        return 'assets/models/telecom/labels.txt';
      default:
        throw Exception("Label file not found for category: $category");
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final rawBytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) {
        print("Failed to decode image.");
        return;
      }
      final resized = img.copyResize(decoded, width: 1280, height: 1280);
      final inputImage = Float32List(1280 * 1280 * 3);
      int index = 0;
      for (int y = 0; y < 1280; y++) {
        for (int x = 0; x < 1280; x++) {
          final p = resized.getPixel(x, y);
          inputImage[index++] = p.r / 255.0;
          inputImage[index++] = p.g / 255.0;
          inputImage[index++] = p.b / 255.0;
        }
      }
      final input = inputImage.reshape([1, 1280, 1280, 3]);
      final outputTensor = _interpreter.getOutputTensor(0);
      final shape = outputTensor.shape;
      final output = List.generate(
        shape[0],
        (_) => List.generate(shape[1], (_) => List.filled(shape[2], 0.0)),
      );

      print("Running inference...");
      _interpreter.run(input, output);
      print("Inference completed.");

      _parseDetections(output[0], threshold: 0.5);
    } catch (e) {
      print("Inference failed: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _parseDetections(List<List<double>> detections, {double threshold = 0.25}) {
    List<Detection> dets = [];

    for (int i = 0; i < detections[0].length; i++) {
      final pred = List.generate(detections.length, (j) => detections[j][i]);
      if (pred.length < 5) continue;

      final cx = pred[0];
      final cy = pred[1];
      final w  = pred[2];
      final h  = pred[3];

      final x = cx - w / 2;
      final y = cy - h / 2;

      final scores   = pred.sublist(4);
      final maxScore = scores.reduce((a, b) => a > b ? a : b);
      final clsIdx   = scores.indexOf(maxScore);
      if (maxScore < threshold) continue;

      final name = (clsIdx < _labels.length) ? _labels[clsIdx] : 'Unknown';

      dets.add(Detection(
        score: maxScore,
        boundingBox: Rect(x: x, y: y, width: w, height: h),
        className: name,
      ));
    }

    final filtered = applyNMS(dets, 0.4);

    for (var det in filtered) {
      print("Final Detection after NMS:");
      print(" - Class: ${det.className}");
      print(" - Confidence: ${det.score.toStringAsFixed(2)}");
      print(" - Bounding Box (x: ${det.boundingBox.x.toStringAsFixed(4)}, "
            "y: ${det.boundingBox.y.toStringAsFixed(4)}, "
            "w: ${det.boundingBox.width.toStringAsFixed(4)}, "
            "h: ${det.boundingBox.height.toStringAsFixed(4)})");
      print("-------------------------");
    }

    setState(() => _finalDetections = filtered);
  }

  List<Detection> applyNMS(List<Detection> dets, double iouThreshold) {
    dets.sort((a, b) => b.score.compareTo(a.score));
    List<Detection> kept = [];
    while (dets.isNotEmpty) {
      final cur = dets.removeAt(0);
      dets.removeWhere((d) =>
        cur.boundingBox.intersectionOverUnion(d.boundingBox) > iouThreshold
      );
      kept.add(cur);
    }
    return kept;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.greenAccent, Colors.green],
          ).createShader(bounds),
          child: Text(
            'Detection Results',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              // Image container with bounding boxes
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base image
                    Image.file(
                      _image,
                      fit: BoxFit.contain,
                    ),
                    
                    // Bounding boxes overlay
                    _buildBoundingBoxes(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Processing indicator
              if (_isProcessing)
                Column(
                  children: [
                    const CircularProgressIndicator(color: Colors.greenAccent),
                    const SizedBox(height: 12),
                    Text(
                      'Processing image...',
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                
              // No detections message
              if (!_isProcessing && _finalDetections.isEmpty)
                Text(
                  'No objects detected.',
                  style: GoogleFonts.robotoCondensed(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                
              // Detected objects list
              if (!_isProcessing && _finalDetections.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Parts',
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                      _finalDetections.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${index + 1}. ${_finalDetections[index].className} (${(_finalDetections[index].score * 100).toStringAsFixed(1)}%)',
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 22,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
              const Spacer(),
              
              // Back button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34A853), Color(0xFF0F9D58)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Back',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
  
  // Separate method to build bounding boxes as an overlay
  Widget _buildBoundingBoxes() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth;
        final imageHeight = constraints.maxHeight;
        
        return Stack(
          children: _finalDetections.map((detection) {
            // Calculate position based on image dimensions
            final left   = detection.boundingBox.x * imageWidth;
            final top    = detection.boundingBox.y * imageHeight;
            final width  = detection.boundingBox.width * imageWidth;
            final height = detection.boundingBox.height * imageHeight;

            return Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      '${detection.className} ${(detection.score * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class Detection {
  final double score;
  final Rect boundingBox;
  final String className;

  Detection({
    required this.score,
    required this.boundingBox,
    required this.className,
  });
}

class Rect {
  final double x, y, width, height;
  Rect({required this.x, required this.y, required this.width, required this.height});

  double get area => width * height;

  double intersectionOverUnion(Rect o) {
    final dx = (x + width).clamp(o.x, o.x + o.width) - x.clamp(o.x, o.x + o.width);
    final dy = (y + height).clamp(o.y, o.y + o.height) - y.clamp(o.y, o.y + o.height);
    if (dx < 0 || dy < 0) return 0;
    final inter = dx * dy;
    final union = area + o.area - inter;
    return inter / union;
  }
}
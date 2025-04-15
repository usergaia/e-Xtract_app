// test_model.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:developer';

class TestModelScreen extends StatefulWidget {
  const TestModelScreen({super.key});

  @override
  State<TestModelScreen> createState() => _TestModelScreenState();
}

class _TestModelScreenState extends State<TestModelScreen> {
  Interpreter? _interpreter;
  File? _selectedImage;
  String _result = "No image selected.";
  List<String> _labels = [];
  List<DetectionResult> _detections = [];

  @override
  void initState() {
    super.initState();
    loadModel();
    loadLabels();
  }

  Future<void> loadLabels() async {
    try {
      String labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n')
          .where((label) => label.trim().isNotEmpty)
          .map((label) => label.trim().split(' ').last) // Extract just the label name from "0 battery"
          .toList();
      log("✅ Loaded ${_labels.length} labels: ${_labels.join(', ')}");
    } catch (e) {
      log("❌ Error loading labels: $e");
      setState(() {
        _result = "❌ Error loading labels: $e";
      });
    }
}

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/best_laptop.tflite');

      var inputTensor = _interpreter!.getInputTensor(0);
      var outputTensor = _interpreter!.getOutputTensor(0);
      log("Input Tensor Shape: ${inputTensor.shape}");
      log("Output Tensor Shape: ${outputTensor.shape}");

      setState(() {
        _result = "✅ Model Loaded Successfully!";
      });
    } catch (e) {
      setState(() {
        _result = "❌ Error loading model: $e";
      });
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _result = "📸 Image Loaded: ${pickedFile.name}";
        _detections = [];
      });
      runModelOnImage(_selectedImage!);
    }
  }

  Future<void> runModelOnImage(File imageFile) async {
    if (_interpreter == null) {
      setState(() {
        _result = "❌ Model not loaded!";
      });
      return;
    }

    var input = await preprocessImage(imageFile);
    var inputBuffer = input.reshape([1, 1280, 1280, 3]);
    var outputBuffer = List.filled(1 * 16 * 33600, 0.0).reshape([1, 16, 33600]);

    try {
      _interpreter!.run(inputBuffer, outputBuffer);
      log("✅ Model Inference Success.");
    } catch (e, stacktrace) {
      log("🔥 Error Running Model: $e", error: e, stackTrace: stacktrace);
      setState(() {
        _result = "❌ Error running model: $e";
      });
      return;
    }

    parseYOLOOutput(outputBuffer);
  }

  Future<Float32List> preprocessImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    img.Image image = img.decodeImage(Uint8List.fromList(imageBytes))!;
    img.Image resizedImage = img.copyResize(image, width: 1280, height: 1280);

    List<double> imageList = [];
    for (int y = 0; y < 1280; y++) {
      for (int x = 0; x < 1280; x++) {
        final pixel = resizedImage.getPixel(x, y);
        imageList.add(pixel.r / 255.0);
        imageList.add(pixel.g / 255.0);
        imageList.add(pixel.b / 255.0);
      }
    }

    return Float32List.fromList(imageList);
  }

  void parseYOLOOutput(List<dynamic> outputBuffer) {
    var output = outputBuffer[0];
    List<DetectionResult> detectionResults = [];
    const double confidenceThreshold = 0.5;

    for (var detection in output) {
      try {
        double x = detection[0];
        double y = detection[1];
        double width = detection[2];
        double height = detection[3];
        double confidence = detection[4];

        List<double> classProbabilities = detection.sublist(5).cast<double>();
        int predictedClass = classProbabilities.indexOf(classProbabilities.reduce((a, b) => a > b ? a : b));
        double classConfidence = classProbabilities[predictedClass];

        if (classConfidence < confidenceThreshold) continue;

        String className = "Unknown (Class $predictedClass)";
        if (_labels.isNotEmpty) {
          int mappedIndex = predictedClass % _labels.length;
          className = _labels[mappedIndex];
        }

        detectionResults.add(
          DetectionResult(
            className: className,
            confidence: classConfidence,
            boundingBox: Rect.fromLTWH(x, y, width, height),
          ),
        );
      } catch (e) {
        log("Error processing detection: $e");
      }
    }

    setState(() {
      _detections = detectionResults;
      _result = detectionResults.isEmpty
          ? "No objects detected"
          : "Detected ${detectionResults.length} objects";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Test Model"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedImage != null) ...[
              const SizedBox(height: 20),
              Stack(
                children: [
                  Image.file(_selectedImage!, height: 300, fit: BoxFit.contain),
                  if (_detections.isNotEmpty)
                    BoundingBoxPainter(
                      imageFile: _selectedImage!,
                      detections: _detections,
                      imageHeight: 300,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Text(
              _result,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_detections.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const Text(
                      "Detection Results",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_detections.length, (index) {
                      final detection = _detections[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text("${index + 1}"),
                        ),
                        title: Text(detection.className, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          "Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => pickImage(ImageSource.camera),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("📸 Capture Image"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => pickImage(ImageSource.gallery),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("🖼 Select from Gallery"),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class DetectionResult {
  final String className;
  final double confidence;
  final Rect boundingBox;

  DetectionResult({
    required this.className,
    required this.confidence,
    required this.boundingBox,
  });
}

class BoundingBoxPainter extends StatelessWidget {
  final File imageFile;
  final List<DetectionResult> detections;
  final double imageHeight;

  const BoundingBoxPainter({
    super.key,
    required this.imageFile,
    required this.detections,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: imageHeight,
          width: constraints.maxWidth,
          child: CustomPaint(
            painter: DetectionPainter(
              detections: detections,
              imageSize: Size(constraints.maxWidth, imageHeight),
            ),
          ),
        );
      },
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Size imageSize;

  DetectionPainter({required this.detections, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = imageSize.width / 1280;
    final double scaleY = imageSize.height / 1280;

    final Paint boxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint textBgPaint = Paint()
      ..color = Colors.red.withAlpha(180)
      ..style = PaintingStyle.fill;

    final TextStyle textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    for (var detection in detections) {
      final double left = detection.boundingBox.left * scaleX;
      final double top = detection.boundingBox.top * scaleY;
      final double width = detection.boundingBox.width * scaleX;
      final double height = detection.boundingBox.height * scaleY;

      final Rect scaledRect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRect(scaledRect, boxPaint);

      final String label = "${detection.className}: ${(detection.confidence * 100).toStringAsFixed(0)}%";
      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();

      final textBackgroundRect = Rect.fromLTWH(
        left,
        top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRect(textBackgroundRect, textBgPaint);

      textPainter.paint(canvas, Offset(left + 4, top - textPainter.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

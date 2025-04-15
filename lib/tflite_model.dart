import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteModel {
  late Interpreter _interpreter;

  // Load the model
  Future<void> loadModel() async {
    try {
      // Load the TFLite model from assets
      _interpreter = await Interpreter.fromAsset('best_laptop.tflite');
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  // Perform inference with the model
  Future<List<dynamic>> runInference(List inputData) async {
    // Prepare input and output buffers for inference
    var input = inputData;
    var output = List.filled(10, 0); // Adjust output size as per model's output

    // Run inference
    _interpreter.run(input, output);
    return output;
  }

  // Close the interpreter when done
  void close() {
    _interpreter.close();
  }
}

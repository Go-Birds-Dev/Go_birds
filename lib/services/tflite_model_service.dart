import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteModelService {
  Interpreter? _interpreter;
  String? _modelName;

  Future<void> loadModel(String assetPath) async {
    _interpreter?.close();
    _interpreter = await Interpreter.fromAsset(assetPath);
    _modelName = assetPath;
  }

  Interpreter? get interpreter => _interpreter;
  String? get modelName => _modelName;

  void close() {
    _interpreter?.close();
    _interpreter = null;
    _modelName = null;
  }
}

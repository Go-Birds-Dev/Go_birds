import 'dart:io';

import 'package:tflite_flutter/tflite_flutter.dart';

/// Thin wrapper around [Interpreter] for asset- or file-backed models.
class TFLiteModelService {
  Interpreter? _interpreter;
  String? _sourceLabel;

  Future<void> loadFromAsset(String assetPath) async {
    _interpreter?.close();
    _interpreter = await Interpreter.fromAsset(assetPath);
    _sourceLabel = 'asset:$assetPath';
  }

  Future<void> loadFromFile(String absolutePath) async {
    _interpreter?.close();
    final file = File(absolutePath);
    _interpreter = Interpreter.fromFile(file);
    _sourceLabel = 'file:$absolutePath';
  }

  Interpreter? get interpreter => _interpreter;
  String? get sourceLabel => _sourceLabel;

  void close() {
    _interpreter?.close();
    _interpreter = null;
    _sourceLabel = null;
  }
}

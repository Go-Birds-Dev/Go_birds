import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../domain/preprocess_kind.dart';

const int kClassifierInputSize = 224;

/// Builds a float32 NHWC tensor [1, 224, 224, 3] matching training preprocess.
List<dynamic> buildInputTensor({
  required img.Image rgbImage,
  required PreprocessKind kind,
}) {
  final inputSize = kClassifierInputSize;
  final resized = img.copyResize(
    rgbImage,
    width: inputSize,
    height: inputSize,
  );

  final List<double> input;
  switch (kind) {
    case PreprocessKind.vgg16MeanBGR:
      input = List.generate(inputSize * inputSize * 3, (i) {
        final c = i % 3;
        final x = (i ~/ 3) % inputSize;
        final y = (i ~/ 3) ~/ inputSize;
        final pixel = resized.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        if (c == 0) return b - 103.939;
        if (c == 1) return g - 116.779;
        return r - 123.68;
      });
    case PreprocessKind.mobilenet255:
      input = List.generate(inputSize * inputSize * 3, (i) {
        final c = i % 3;
        final x = (i ~/ 3) % inputSize;
        final y = (i ~/ 3) ~/ inputSize;
        final pixel = resized.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        if (c == 0) return r / 255.0;
        if (c == 1) return g / 255.0;
        return b / 255.0;
      });
  }

  return Float32List.fromList(input).reshape([1, inputSize, inputSize, 3]);
}

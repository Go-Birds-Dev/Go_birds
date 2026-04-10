import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../data/bird_common_names.dart';
import '../data/bird_labels_repository.dart';
import '../domain/prediction_result.dart';
import '../domain/resolved_model.dart';
import 'image_preprocessor.dart';
import 'tflite_model_service.dart';

/// Loads TFLite weights + labels for a [ResolvedModel] and runs inference.
class BirdClassifier {
  BirdClassifier({
    TFLiteModelService? tflite,
    BirdLabelsRepository? labelsRepository,
  })  : _tflite = tflite ?? TFLiteModelService(),
        _labelsRepository = labelsRepository ?? const BirdLabelsRepository();

  final TFLiteModelService _tflite;
  final BirdLabelsRepository _labelsRepository;

  String? _preparedKey;
  List<String>? _classNames;

  TFLiteModelService get tflite => _tflite;

  Future<void> prepare(ResolvedModel model) async {
    if (_preparedKey == model.cacheKey) return;

    _tflite.close();
    if (model.usesBundledModel) {
      await _tflite.loadFromAsset(model.modelPath);
    } else {
      await _tflite.loadFromFile(model.modelPath);
    }

    _classNames = await _labelsRepository.load(
      fromBundledAsset: model.usesBundledLabels,
      path: model.labelsPath,
    );
    _preparedKey = model.cacheKey;
  }

  void reset() {
    _tflite.close();
    _preparedKey = null;
    _classNames = null;
  }

  Future<PredictionResult> predictFile(File imageFile, ResolvedModel model) async {
    await prepare(model);
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw StateError('No se pudo decodificar la imagen');
    }

    final inputTensor = buildInputTensor(rgbImage: image, kind: model.preprocessKind);
    final interpreter = _tflite.interpreter;
    if (interpreter == null) {
      throw StateError('Modelo no cargado');
    }

    final outputShape = interpreter.getOutputTensor(0).shape;
    final output = Float32List(outputShape.reduce((a, b) => a * b)).reshape(outputShape);
    interpreter.run(inputTensor, output);

    var probs = List<double>.from(output.expand((e) => e is List ? e : [e]));
    final sum = probs.fold(0.0, (a, b) => a + b);
    if (sum < 0.99 || sum > 1.01) {
      probs = probs.map((v) => v / sum).toList();
    }

    final topIdx = List.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));
    final top3 = topIdx.take(3).toList();
    final labels = _classNames ?? const <String>[];

    final scored = <ScoredLabel>[];
    final buf = StringBuffer();
    String? topScientific;

    for (var i = 0; i < top3.length; i++) {
      final idx = top3[i];
      final prob = probs[idx];
      String sci = 'Desconocido';
      String com = 'Desconocido';
      if (labels.isNotEmpty && idx >= 0 && idx < labels.length) {
        sci = labels[idx];
        com = commonNameForScientific(sci);
      }
      if (i == 0) topScientific = sci;

      scored.add(
        ScoredLabel(
          scientificName: sci,
          commonName: com,
          probability: prob,
          rank: i + 1,
        ),
      );

      final medal = i == 0 ? '🥇' : (i == 1 ? '🥈' : '🥉');
      buf.writeln('$medal ${i + 1}. $com');
      buf.writeln('   Científico: $sci');
      buf.writeln('   Confianza: ${(prob * 100).toStringAsFixed(2)}%');
      if (i < 2) buf.writeln();
    }

    return PredictionResult(
      topLabels: scored,
      formattedSummary: buf.toString().trim(),
      topScientificName: topScientific,
    );
  }
}

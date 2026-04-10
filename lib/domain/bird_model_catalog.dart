import 'bird_model_spec.dart';
import 'preprocess_kind.dart';

/// Built-in models shipped with the app (also used when remote sync is disabled).
const List<BirdModelSpec> kBirdModelCatalog = [
  BirdModelSpec(
    id: 'vgg16_aves',
    displayName: 'VGG16',
    preprocessKind: PreprocessKind.vgg16MeanBGR,
    bundledModelAsset: 'assets/models/vgg16_aves.tflite',
    bundledLabelsAsset: 'assets/classes.txt',
  ),
  BirdModelSpec(
    id: 'mobilenet_v2_aves',
    displayName: 'MobileNetV2',
    preprocessKind: PreprocessKind.mobilenet255,
    bundledModelAsset: 'assets/models/mobilenet_v2_aves.tflite',
    bundledLabelsAsset: 'assets/classes.txt',
  ),
  BirdModelSpec(
    id: 'densenet_aves',
    displayName: 'DenseNet',
    preprocessKind: PreprocessKind.mobilenet255,
    bundledModelAsset: 'assets/models/modelo_final_densenet.tflite',
    bundledLabelsAsset: 'assets/classes_densenet.txt',
  ),
];

BirdModelSpec? birdSpecById(String id) {
  for (final s in kBirdModelCatalog) {
    if (s.id == id) return s;
  }
  return null;
}

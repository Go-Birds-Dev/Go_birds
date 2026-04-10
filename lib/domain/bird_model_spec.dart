import 'preprocess_kind.dart';

/// Static definition of a bird classifier variant (bundled + optional remote id).
class BirdModelSpec {
  const BirdModelSpec({
    required this.id,
    required this.displayName,
    required this.preprocessKind,
    required this.bundledModelAsset,
    required this.bundledLabelsAsset,
    this.remoteModelId,
  });

  /// Stable key used in manifest JSON and local cache directories.
  final String id;

  final String displayName;
  final PreprocessKind preprocessKind;

  /// Asset path packaged in the app (offline bootstrap).
  final String bundledModelAsset;
  final String bundledLabelsAsset;

  /// Manifest `models[].id` when published remotely; defaults to [id] if omitted.
  final String? remoteModelId;

  String get manifestId => remoteModelId ?? id;
}

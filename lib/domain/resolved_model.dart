import 'preprocess_kind.dart';

/// Concrete paths to load after sync (bundled assets or downloaded files).
class ResolvedModel {
  const ResolvedModel({
    required this.specId,
    required this.displayName,
    required this.preprocessKind,
    required this.modelPath,
    required this.labelsPath,
    required this.usesBundledModel,
    required this.usesBundledLabels,
    this.remoteRevision,
  });

  final String specId;
  final String displayName;
  final PreprocessKind preprocessKind;

  /// Asset path (e.g. `assets/...`) or absolute file path.
  final String modelPath;
  final String labelsPath;
  final bool usesBundledModel;
  final bool usesBundledLabels;

  /// Non-null when weights/labels came from remote cache.
  final String? remoteRevision;

  String get cacheKey =>
      remoteRevision != null ? '$specId@$remoteRevision' : '$specId@bundled';

  bool get isReady => modelPath.isNotEmpty && labelsPath.isNotEmpty;
}

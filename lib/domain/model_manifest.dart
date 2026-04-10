/// Remote manifest describing downloadable model revisions.
class ModelManifest {
  const ModelManifest({
    required this.schemaVersion,
    required this.models,
  });

  final int schemaVersion;
  final List<RemoteModelEntry> models;

  factory ModelManifest.fromJson(Map<String, dynamic> json) {
    final raw = json['models'];
    final list = raw is List
        ? raw
            .map((e) => RemoteModelEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <RemoteModelEntry>[];
    return ModelManifest(
      schemaVersion: (json['schema'] as num?)?.toInt() ?? 1,
      models: list,
    );
  }
}

class RemoteModelEntry {
  const RemoteModelEntry({
    required this.id,
    required this.revision,
    required this.tfliteUrl,
    required this.labelsUrl,
    required this.sha256Tflite,
    required this.sha256Labels,
    this.minSupportedAppVersion,
  });

  final String id;
  final String revision;
  final String tfliteUrl;
  final String labelsUrl;
  final String sha256Tflite;
  final String sha256Labels;
  final String? minSupportedAppVersion;

  factory RemoteModelEntry.fromJson(Map<String, dynamic> json) {
    return RemoteModelEntry(
      id: json['id'] as String? ?? '',
      revision: json['revision'] as String? ?? '',
      tfliteUrl: json['tflite_url'] as String? ?? '',
      labelsUrl: json['labels_url'] as String? ?? '',
      sha256Tflite: (json['sha256_tflite'] as String? ?? '').toLowerCase(),
      sha256Labels: (json['sha256_labels'] as String? ?? '').toLowerCase(),
      minSupportedAppVersion: json['min_supported_app_version'] as String?,
    );
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persisted mapping of model id → last successfully applied remote revision + paths.
class ModelCacheStore {
  ModelCacheStore(this._prefs);

  static const _key = 'go_birds_model_cache_v1';
  static const _manifestUrlKey = 'go_birds_manifest_url';
  static const _lastSyncKey = 'go_birds_last_sync_ms';

  final SharedPreferences _prefs;

  Map<String, CachedModelPaths> readCache() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) {
        final m = Map<String, dynamic>.from(v as Map);
        return MapEntry(
          k,
          CachedModelPaths(
            revision: m['revision'] as String? ?? '',
            tflitePath: m['tflitePath'] as String? ?? '',
            labelsPath: m['labelsPath'] as String? ?? '',
          ),
        );
      });
    } catch (_) {
      return {};
    }
  }

  Future<void> writeCache(Map<String, CachedModelPaths> data) async {
    final encoded = jsonEncode(
      data.map((k, v) => MapEntry(k, v.toJson())),
    );
    await _prefs.setString(_key, encoded);
  }

  Future<void> updateEntry(String modelId, CachedModelPaths paths) async {
    final all = readCache();
    all[modelId] = paths;
    await writeCache(all);
  }

  String? get manifestUrlOrNull {
    final u = _prefs.getString(_manifestUrlKey);
    if (u == null || u.trim().isEmpty) return null;
    return u.trim();
  }

  Future<void> setManifestUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _prefs.remove(_manifestUrlKey);
    } else {
      await _prefs.setString(_manifestUrlKey, url.trim());
    }
  }

  DateTime? get lastSyncedAt {
    final ms = _prefs.getInt(_lastSyncKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastSyncedAt(DateTime t) =>
      _prefs.setInt(_lastSyncKey, t.millisecondsSinceEpoch);
}

class CachedModelPaths {
  const CachedModelPaths({
    required this.revision,
    required this.tflitePath,
    required this.labelsPath,
  });

  final String revision;
  final String tflitePath;
  final String labelsPath;

  Map<String, String> toJson() => {
        'revision': revision,
        'tflitePath': tflitePath,
        'labelsPath': labelsPath,
      };
}

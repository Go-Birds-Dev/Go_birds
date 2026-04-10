import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../domain/bird_model_catalog.dart';
import '../domain/bird_model_spec.dart';
import '../domain/model_manifest.dart';
import '../domain/resolved_model.dart';
import 'model_cache_store.dart';

/// Fetches the remote manifest, downloads artifacts, verifies SHA-256, and
/// resolves [ResolvedModel] entries (falling back to bundled assets).
class ModelUpdateRepository {
  ModelUpdateRepository({
    required http.Client httpClient,
    required ModelCacheStore cacheStore,
  }) : _client = httpClient,
       _cacheStore = cacheStore;

  final http.Client _client;
  final ModelCacheStore _cacheStore;

  Future<Directory> _modelRoot() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/go_birds_models');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  ResolvedModel _bundled(BirdModelSpec spec) {
    return ResolvedModel(
      specId: spec.id,
      displayName: spec.displayName,
      preprocessKind: spec.preprocessKind,
      modelPath: spec.bundledModelAsset,
      labelsPath: spec.bundledLabelsAsset,
      usesBundledModel: true,
      usesBundledLabels: true,
      remoteRevision: null,
    );
  }

  Future<ModelManifest?> _fetchManifest(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return null;
    final res = await _client.get(uri).timeout(const Duration(seconds: 45));
    if (res.statusCode != 200) return null;
    final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return ModelManifest.fromJson(map);
  }

  RemoteModelEntry? _entryFor(ModelManifest? m, BirdModelSpec spec) {
    if (m == null) return null;
    for (final e in m.models) {
      if (e.id == spec.manifestId) return e;
    }
    return null;
  }

  bool _validHexSha256(String s) => RegExp(r'^[a-f0-9]{64}$').hasMatch(s);

  Future<void> _writeAndVerify({
    required File target,
    required List<int> bytes,
    required String expectedSha256,
  }) async {
    final digest = sha256.convert(bytes).toString();
    if (_validHexSha256(expectedSha256) && digest != expectedSha256) {
      throw StateError('SHA-256 mismatch for ${target.path}');
    }
    await target.parent.create(recursive: true);
    final part = File('${target.path}.part');
    await part.writeAsBytes(bytes, flush: true);
    if (await target.exists()) await target.delete();
    await part.rename(target.path);
  }

  Future<void> _downloadTo({
    required String url,
    required File target,
    required String expectedSha256,
  }) async {
    final uri = Uri.parse(url);
    final res = await _client.get(uri).timeout(const Duration(minutes: 5));
    if (res.statusCode != 200) {
      throw HttpException('HTTP ${res.statusCode} for $url');
    }
    await _writeAndVerify(
      target: target,
      bytes: res.bodyBytes,
      expectedSha256: expectedSha256,
    );
  }

  /// Resolves catalog using only persisted cache + bundled fallback (no network).
  Future<List<ResolvedModel>> resolveOffline() async {
    final cached = _cacheStore.readCache();
    final out = <ResolvedModel>[];
    for (final spec in kBirdModelCatalog) {
      final c = cached[spec.id];
      if (c != null &&
          c.tflitePath.isNotEmpty &&
          c.labelsPath.isNotEmpty &&
          await File(c.tflitePath).exists() &&
          await File(c.labelsPath).exists()) {
        out.add(
          ResolvedModel(
            specId: spec.id,
            displayName: spec.displayName,
            preprocessKind: spec.preprocessKind,
            modelPath: c.tflitePath,
            labelsPath: c.labelsPath,
            usesBundledModel: false,
            usesBundledLabels: false,
            remoteRevision: c.revision,
          ),
        );
      } else {
        out.add(_bundled(spec));
      }
    }
    return out;
  }

  /// Fetches manifest when [manifestUrl] is non-empty; updates cache; returns resolved models.
  Future<ModelSyncResult> refresh({String? manifestUrl}) async {
    final url = manifestUrl ?? _cacheStore.manifestUrlOrNull;
    if (url == null || url.isEmpty) {
      final models = await resolveOffline();
      return ModelSyncResult(
        models: models,
        usedRemote: false,
        errorMessage: null,
        syncedAt: _cacheStore.lastSyncedAt,
      );
    }

    ModelManifest? manifest;
    try {
      manifest = await _fetchManifest(url);
    } catch (e) {
      final fallback = await resolveOffline();
      return ModelSyncResult(
        models: fallback,
        usedRemote: false,
        errorMessage: 'Manifesto no disponible: $e',
        syncedAt: _cacheStore.lastSyncedAt,
      );
    }

    if (manifest == null) {
      final fallback = await resolveOffline();
      return ModelSyncResult(
        models: fallback,
        usedRemote: false,
        errorMessage: 'No se pudo leer el manifiesto remoto.',
        syncedAt: _cacheStore.lastSyncedAt,
      );
    }

    final root = await _modelRoot();
    final persisted = _cacheStore.readCache();
    final next = Map<String, CachedModelPaths>.from(persisted);
    final out = <ResolvedModel>[];
    String? firstError;

    for (final spec in kBirdModelCatalog) {
      final remote = _entryFor(manifest, spec);
      if (remote == null ||
          remote.revision.isEmpty ||
          remote.tfliteUrl.isEmpty ||
          remote.labelsUrl.isEmpty) {
        out.add(_bundled(spec));
        continue;
      }

      final existing = persisted[spec.id];
      final dir = Directory('${root.path}/${spec.id}/${remote.revision}');
      final tfliteFile = File('${dir.path}/model.tflite');
      final labelsFile = File('${dir.path}/labels.txt');

      final haveFiles = await tfliteFile.exists() && await labelsFile.exists();
      final sameRevision = existing?.revision == remote.revision;

      try {
        if (!sameRevision || !haveFiles) {
          await _downloadTo(
            url: remote.tfliteUrl,
            target: tfliteFile,
            expectedSha256: remote.sha256Tflite,
          );
          await _downloadTo(
            url: remote.labelsUrl,
            target: labelsFile,
            expectedSha256: remote.sha256Labels,
          );
          next[spec.id] = CachedModelPaths(
            revision: remote.revision,
            tflitePath: tfliteFile.path,
            labelsPath: labelsFile.path,
          );
        } else {
          next[spec.id] = CachedModelPaths(
            revision: remote.revision,
            tflitePath: tfliteFile.path,
            labelsPath: labelsFile.path,
          );
        }

        out.add(
          ResolvedModel(
            specId: spec.id,
            displayName: spec.displayName,
            preprocessKind: spec.preprocessKind,
            modelPath: tfliteFile.path,
            labelsPath: labelsFile.path,
            usesBundledModel: false,
            usesBundledLabels: false,
            remoteRevision: remote.revision,
          ),
        );
      } catch (e) {
        firstError ??= '$e';
        if (existing != null &&
            await File(existing.tflitePath).exists() &&
            await File(existing.labelsPath).exists()) {
          out.add(
            ResolvedModel(
              specId: spec.id,
              displayName: spec.displayName,
              preprocessKind: spec.preprocessKind,
              modelPath: existing.tflitePath,
              labelsPath: existing.labelsPath,
              usesBundledModel: false,
              usesBundledLabels: false,
              remoteRevision: existing.revision,
            ),
          );
        } else {
          out.add(_bundled(spec));
        }
      }
    }

    await _cacheStore.writeCache(next);
    final now = DateTime.now();
    await _cacheStore.setLastSyncedAt(now);

    return ModelSyncResult(
      models: out,
      usedRemote: true,
      errorMessage: firstError,
      syncedAt: now,
    );
  }
}

class ModelSyncResult {
  const ModelSyncResult({
    required this.models,
    required this.usedRemote,
    required this.errorMessage,
    required this.syncedAt,
  });

  final List<ResolvedModel> models;
  final bool usedRemote;
  final String? errorMessage;
  final DateTime? syncedAt;
}

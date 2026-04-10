import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

/// Loads newline-delimited class names from a bundled asset or a local file.
class BirdLabelsRepository {
  const BirdLabelsRepository();

  Future<List<String>> load({
    required bool fromBundledAsset,
    required String path,
  }) async {
    final String content;
    if (fromBundledAsset) {
      content = await rootBundle.loadString(path);
    } else {
      content = await File(path).readAsString();
    }
    return content
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

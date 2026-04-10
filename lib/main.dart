import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app/go_birds_app.dart';
import 'data/model_cache_store.dart';
import 'data/model_update_repository.dart';
import 'inference/bird_classifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final cacheStore = ModelCacheStore(prefs);
  final httpClient = http.Client();
  final modelUpdateRepository = ModelUpdateRepository(
    httpClient: httpClient,
    cacheStore: cacheStore,
  );
  final birdClassifier = BirdClassifier();

  runApp(
    GoBirdsApp(
      modelUpdateRepository: modelUpdateRepository,
      birdClassifier: birdClassifier,
    ),
  );
}

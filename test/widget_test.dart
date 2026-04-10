import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:go_birds/app/go_birds_app.dart';
import 'package:go_birds/app/main_navigation.dart';
import 'package:go_birds/data/model_cache_store.dart';
import 'package:go_birds/data/model_update_repository.dart';
import 'package:go_birds/inference/bird_classifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app shows prediction tab', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheStore = ModelCacheStore(prefs);
    final httpClient = http.Client();
    final modelUpdateRepository = ModelUpdateRepository(
      httpClient: httpClient,
      cacheStore: cacheStore,
    );

    await tester.pumpWidget(
      GoBirdsApp(
        modelUpdateRepository: modelUpdateRepository,
        birdClassifier: BirdClassifier(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(MainNavigation), findsOneWidget);
    expect(find.text('Predicción'), findsOneWidget);
  });
}

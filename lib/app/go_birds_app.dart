import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/model_update_repository.dart';
import '../features/prediction/bloc/model_sync_cubit.dart';
import '../features/prediction/bloc/prediction_bloc.dart';
import '../inference/bird_classifier.dart';
import 'main_navigation.dart';

class GoBirdsApp extends StatelessWidget {
  const GoBirdsApp({
    super.key,
    required this.modelUpdateRepository,
    required this.birdClassifier,
  });

  final ModelUpdateRepository modelUpdateRepository;
  final BirdClassifier birdClassifier;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final sync = ModelSyncCubit(modelUpdateRepository);
            sync.refresh();
            return sync;
          },
        ),
        BlocProvider(
          create: (_) => PredictionBloc(classifier: birdClassifier),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Clasificador de Aves',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const MainNavigation(),
      ),
    );
  }
}

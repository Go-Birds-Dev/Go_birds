import 'dart:io';

import '../../../domain/resolved_model.dart';

sealed class PredictionEvent {}

final class PredictionCatalogUpdated extends PredictionEvent {
  PredictionCatalogUpdated(this.models);
  final List<ResolvedModel> models;
}

final class PredictionModelSelected extends PredictionEvent {
  PredictionModelSelected(this.specId);
  final String specId;
}

final class PredictionImagePicked extends PredictionEvent {
  PredictionImagePicked(this.file);
  final File file;
}

final class PredictionImageCleared extends PredictionEvent {}

final class PredictionRunRequested extends PredictionEvent {}

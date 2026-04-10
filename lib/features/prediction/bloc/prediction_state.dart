import 'dart:io';

import '../../../domain/prediction_result.dart';
import '../../../domain/resolved_model.dart';

class PredictionState {
  const PredictionState({
    this.catalog = const [],
    this.selectedSpecId,
    this.imageFile,
    this.modelPrepareBusy = false,
    this.predictionBusy = false,
    this.statusMessage,
    this.errorMessage,
    this.result,
  });

  final List<ResolvedModel> catalog;
  final String? selectedSpecId;
  final File? imageFile;
  final bool modelPrepareBusy;
  final bool predictionBusy;
  final String? statusMessage;
  final String? errorMessage;
  final PredictionResult? result;

  bool get isBusy => modelPrepareBusy || predictionBusy;

  ResolvedModel? get selectedResolved {
    final id = selectedSpecId;
    if (id == null) {
      return catalog.isEmpty ? null : catalog.first;
    }
    for (final m in catalog) {
      if (m.specId == id) return m;
    }
    return catalog.isEmpty ? null : catalog.first;
  }

  PredictionState copyWith({
    List<ResolvedModel>? catalog,
    String? selectedSpecId,
    File? imageFile,
    bool? modelPrepareBusy,
    bool? predictionBusy,
    String? statusMessage,
    String? errorMessage,
    PredictionResult? result,
    bool clearImage = false,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return PredictionState(
      catalog: catalog ?? this.catalog,
      selectedSpecId: selectedSpecId ?? this.selectedSpecId,
      imageFile: clearImage ? null : (imageFile ?? this.imageFile),
      modelPrepareBusy: modelPrepareBusy ?? this.modelPrepareBusy,
      predictionBusy: predictionBusy ?? this.predictionBusy,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

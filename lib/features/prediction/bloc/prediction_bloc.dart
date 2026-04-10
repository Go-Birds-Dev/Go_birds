import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/bird_model_catalog.dart';
import '../../../domain/resolved_model.dart';
import '../../../inference/bird_classifier.dart';
import 'prediction_event.dart';
import 'prediction_state.dart';

class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  PredictionBloc({required BirdClassifier classifier})
      : _classifier = classifier,
        super(const PredictionState()) {
    on<PredictionCatalogUpdated>(_onCatalogUpdated);
    on<PredictionModelSelected>(_onModelSelected);
    on<PredictionImagePicked>(_onImagePicked);
    on<PredictionImageCleared>(_onImageCleared);
    on<PredictionRunRequested>(_onRunRequested);
  }

  final BirdClassifier _classifier;

  Future<void> _onCatalogUpdated(
    PredictionCatalogUpdated event,
    Emitter<PredictionState> emit,
  ) async {
    final nextCatalog = event.models;
    var sel = state.selectedSpecId;
    if (sel == null || !nextCatalog.any((m) => m.specId == sel)) {
      sel = nextCatalog.isEmpty ? null : nextCatalog.first.specId;
    }
    emit(
      state.copyWith(
        catalog: nextCatalog,
        selectedSpecId: sel,
        clearError: true,
      ),
    );
    final resolved = _resolvedOrNull(sel, nextCatalog);
    if (resolved != null) {
      await _prepareModel(resolved, emit);
    }
  }

  Future<void> _onModelSelected(
    PredictionModelSelected event,
    Emitter<PredictionState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedSpecId: event.specId,
        clearResult: true,
        clearError: true,
        statusMessage: 'Cargando modelo...',
      ),
    );
    final resolved = _resolvedOrNull(event.specId, state.catalog);
    if (resolved != null) {
      await _prepareModel(resolved, emit);
    }
  }

  ResolvedModel? _resolvedOrNull(String? id, List<ResolvedModel> catalog) {
    if (id == null) return null;
    for (final m in catalog) {
      if (m.specId == id) return m;
    }
    return null;
  }

  Future<void> _prepareModel(
    ResolvedModel model,
    Emitter<PredictionState> emit,
  ) async {
    emit(state.copyWith(modelPrepareBusy: true));
    try {
      await _classifier.prepare(model);
      final spec = birdSpecById(model.specId);
      emit(
        state.copyWith(
          modelPrepareBusy: false,
          statusMessage: spec != null
              ? 'Modelo cargado: ${model.displayName}'
              : 'Modelo listo',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          modelPrepareBusy: false,
          errorMessage: 'Error al cargar el modelo: $e',
          statusMessage: null,
        ),
      );
    }
  }

  void _onImagePicked(
    PredictionImagePicked event,
    Emitter<PredictionState> emit,
  ) {
    emit(
      state.copyWith(
        imageFile: event.file,
        clearResult: true,
        clearError: true,
        statusMessage: null,
      ),
    );
  }

  void _onImageCleared(
    PredictionImageCleared event,
    Emitter<PredictionState> emit,
  ) {
    emit(
      state.copyWith(
        clearImage: true,
        clearResult: true,
        clearError: true,
      ),
    );
  }

  Future<void> _onRunRequested(
    PredictionRunRequested event,
    Emitter<PredictionState> emit,
  ) async {
    final file = state.imageFile;
    final model = state.selectedResolved;
    if (file == null || model == null) return;

    emit(
      state.copyWith(
        predictionBusy: true,
        clearError: true,
        statusMessage: 'Procesando imagen...',
      ),
    );
    try {
      await _classifier.prepare(model);
      final result = await _classifier.predictFile(file, model);
      emit(
        state.copyWith(
          predictionBusy: false,
          result: result,
          statusMessage: 'Predicción realizada',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          predictionBusy: false,
          statusMessage: null,
          errorMessage: 'Error en la predicción: $e',
        ),
      );
    }
  }

}

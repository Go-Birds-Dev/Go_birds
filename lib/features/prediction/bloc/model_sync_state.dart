import '../../../domain/resolved_model.dart';

/// Remote manifest sync + resolved model paths for the UI.
class ModelSyncState {
  const ModelSyncState({
    this.isRefreshing = false,
    this.models = const [],
    this.warning,
    this.lastSyncedAt,
  });

  final bool isRefreshing;
  final List<ResolvedModel> models;
  final String? warning;
  final DateTime? lastSyncedAt;

  ModelSyncState copyWith({
    bool? isRefreshing,
    List<ResolvedModel>? models,
    String? warning,
    DateTime? lastSyncedAt,
    bool clearWarning = false,
  }) {
    return ModelSyncState(
      isRefreshing: isRefreshing ?? this.isRefreshing,
      models: models ?? this.models,
      warning: clearWarning ? null : warning ?? this.warning,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

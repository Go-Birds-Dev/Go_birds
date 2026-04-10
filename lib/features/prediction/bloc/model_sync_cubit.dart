import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/model_update_repository.dart';
import 'model_sync_state.dart';

/// Loads bundled/offline models first, then refreshes from the remote manifest.
class ModelSyncCubit extends Cubit<ModelSyncState> {
  ModelSyncCubit(this._repository) : super(const ModelSyncState());

  final ModelUpdateRepository _repository;
  Timer? _periodic;

  /// Call on app start and for manual refresh.
  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true, clearWarning: true));
    try {
      final quick = await _repository.resolveOffline();
      emit(state.copyWith(models: quick, isRefreshing: true));
      final result = await _repository.refresh();
      emit(
        state.copyWith(
          models: result.models,
          isRefreshing: false,
          warning: result.errorMessage,
          clearWarning: result.errorMessage == null,
          lastSyncedAt: result.syncedAt ?? state.lastSyncedAt,
        ),
      );
    } catch (e) {
      final offline = await _repository.resolveOffline();
      emit(
        state.copyWith(
          models: offline,
          isRefreshing: false,
          warning: '$e',
        ),
      );
    }

    _periodic ??= Timer.periodic(const Duration(hours: 24), (_) => refresh());
  }

  @override
  Future<void> close() {
    _periodic?.cancel();
    return super.close();
  }
}

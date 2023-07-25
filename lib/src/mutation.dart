import 'package:fquery/fquery.dart';
import 'package:fquery/src/mutation_observer.dart';

enum MutationDispatchAction {
  mutate,
  error,
  success,
}

enum MutationStatus {
  idle,
  loading,
  success,
  error,
}

class MutationState<TData, TError> {
  TData? data;
  TError? error;
  DateTime? dataUpdatedAt;
  DateTime? errorUpdatedAt;
  MutationStatus status;

  bool get isIdle => status == MutationStatus.idle;
  bool get isLoading => status == MutationStatus.loading;
  bool get isSuccess => status == MutationStatus.success;
  bool get isError => status == MutationStatus.error;

  MutationState({
    this.data,
    this.error,
    this.dataUpdatedAt,
    this.errorUpdatedAt,
    this.status = MutationStatus.idle,
  });

  MutationState<TData, TError> _copyWith({
    dynamic data,
    dynamic error,
    DateTime? dataUpdatedAt,
    DateTime? errorUpdatedAt,
    MutationStatus? status,
  }) =>
      MutationState<TData, TError>(
        data: data ?? this.data,
        error: error ?? this.error,
        dataUpdatedAt: dataUpdatedAt ?? this.dataUpdatedAt,
        errorUpdatedAt: errorUpdatedAt ?? this.errorUpdatedAt,
        status: status ?? this.status,
      );
}

class Mutation<TVariables, TData, TError> {
  final QueryClient client;
  MutationState<TData, TError> _state = MutationState();
  MutationState<TData, TError> get state => _state;
  final MutationObserver<TVariables, TData, TError> observer;

  Mutation({
    required this.client,
    required this.observer,
  });

  MutationState<TData, TError> _reducer(
    MutationState<TData, TError> state,
    MutationDispatchAction action,
    dynamic data,
  ) {
    switch (action) {
      case MutationDispatchAction.mutate:
        return state._copyWith(status: MutationStatus.loading);
      case MutationDispatchAction.error:
        return state._copyWith(
          error: data,
          errorUpdatedAt: DateTime.now(),
          status: MutationStatus.error,
        );
      case MutationDispatchAction.success:
        return state._copyWith(
          data: data,
          dataUpdatedAt: DateTime.now(),
          status: MutationStatus.success,
        );
      default:
        return state;
    }
  }

  void dispatch(MutationDispatchAction action, dynamic data) {
    _state = _reducer(state, action, data);
    observer.onMutationUpdated();
  }
}

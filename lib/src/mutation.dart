// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:fquery/fquery.dart';
import 'package:fquery/src/mutation_observer.dart';

enum MutationDispatchAction {
  reset,
  mutate,
  error,
  success,
}

enum MutationStatus {
  idle,
  pending,
  success,
  error,
}

class MutationState<TData, TError> {
  TData? data;
  TError? error;
  DateTime? submittedAt;
  MutationStatus status;

  bool get isIdle => status == MutationStatus.idle;
  bool get isPending => status == MutationStatus.pending;
  bool get isSuccess => status == MutationStatus.success;
  bool get isError => status == MutationStatus.error;

  MutationState({
    this.data,
    this.error,
    this.status = MutationStatus.idle,
    this.submittedAt,
  });

  MutationState<TData, TError> copyWith({
    TData? data,
    TError? error,
    DateTime? submittedAt,
    MutationStatus? status,
  }) {
    return MutationState<TData, TError>(
      data: data ?? this.data,
      error: error ?? this.error,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
    );
  }
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
      case MutationDispatchAction.reset:
        return MutationState();
      case MutationDispatchAction.mutate:
        return state.copyWith(
          status: MutationStatus.pending,
          submittedAt: DateTime.now(),
        );
      case MutationDispatchAction.error:
        return state.copyWith(
          error: data,
          status: MutationStatus.error,
        );
      case MutationDispatchAction.success:
        return state.copyWith(
          data: data,
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

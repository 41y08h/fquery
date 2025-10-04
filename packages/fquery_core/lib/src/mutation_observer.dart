import 'dart:async';

import 'package:fquery_core/src/mutation.dart';
import 'package:fquery_core/src/observer.dart';

/// A [MutationObserver] is a class which holds a [Mutation] and handles its execution.
class MutationObserver<TData, TError, TVariables, TContext> with Observable {
  /// The options used to configure the mutation.
  late MutationOptions<TData, TError, TVariables, TContext> options;

  /// The mutation instance managed by this observer.
  late Mutation<TData, TError> mutation;

  /// The variables used in the last mutation.
  TVariables? vars;

  MutationObserver({
    required this.options,
  }) {
    mutation = Mutation<TData, TError>();
  }

  void dispose() {
    disposeSubscribers();
  }

  /// This is "the" function responsible for the mutation.
  Future<void> mutate(TVariables variables) async {
    if (mutation.isPending) return;

    this.vars = variables;
    onMutationUpdated();

    dispatch(MutationDispatchAction.mutate, null);
    final ctx = await options.onMutate?.call(variables);

    TData? data;
    TError? error;
    try {
      error = null;
      data = await options.mutationFn(variables);
      dispatch(MutationDispatchAction.success, data);
      options.onSuccess?.call(data as TData, variables, ctx);
    } catch (err) {
      data = null;
      error = err as TError;
      dispatch(MutationDispatchAction.error, error);
      options.onError?.call(error as TError, variables, ctx);
    }
    options.onSettled?.call(data, error, variables, ctx);
  }

  /// Resets the mutation to its initial state.
  void reset() {
    dispatch(MutationDispatchAction.reset, null);
  }

  /// This is called from the [Mutation] class whenever the mutation state changes.
  /// It notifies the observer about the change and it also nofities the [useMutation] hook.
  void onMutationUpdated() {
    notifyObservers();
  }

  Mutation<TData, TError> _reducer(
    Mutation<TData, TError> state,
    MutationDispatchAction action,
    dynamic data,
  ) {
    switch (action) {
      case MutationDispatchAction.reset:
        return Mutation();
      case MutationDispatchAction.mutate:
        return state.copyWith(
          status: MutationStatus.pending,
          submittedAt: DateTime.now(),
        );
      case MutationDispatchAction.error:
        return state.copyWith(error: data, status: MutationStatus.error);
      case MutationDispatchAction.success:
        return state.copyWith(data: data, status: MutationStatus.success);
    }
  }

  void dispatch(MutationDispatchAction action, dynamic data) {
    mutation = _reducer(mutation, action, data);
    notifyObservers();
  }
}

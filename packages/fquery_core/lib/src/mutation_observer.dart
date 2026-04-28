import 'dart:async';

import 'package:fquery_core/src/mutation.dart';
import 'package:fquery_core/src/observer.dart';

/// A [MutationObserver] manages the execution and state of a single mutation.
///
/// It handles the complete lifecycle of a mutation, including:
/// - Executing the mutation function
/// - Managing state transitions (idle to pending to success/error)
/// - Invoking lifecycle callbacks (onMutate, onSuccess, onError, onSettled)
/// - Preventing concurrent mutations
/// - Notifying subscribers of state changes
///
/// Type parameters:
/// - `TData`: The type of data returned by the mutation on success
/// - `TError`: The type of error thrown by the mutation
/// - `TVariables`: The type of variables passed to the mutation
/// - `TContext`: The type of context returned by the onMutate callback
class MutationObserver<TData, TError extends Exception, TVariables, TContext>
    with Observable {
  /// The options used to configure the mutation.
  late MutationOptions<TData, TError, TVariables, TContext> options;

  /// The mutation instance managed by this observer.
  ///
  /// This represents the current state of the mutation and is updated
  /// as the mutation progresses through its lifecycle.
  late Mutation<TData, TError> mutation;

  /// The variables used in the last mutation execution.
  TVariables? vars;

  /// Creates a new [MutationObserver] instance.
  ///
  /// Initializes the mutation to an idle state with no data or error.
  MutationObserver({
    required this.options,
  }) {
    mutation = Mutation<TData, TError>();
  }

  /// Disposes the observer and clears all subscribers.
  ///
  /// Should be called when the observer is no longer needed to prevent
  /// memory leaks from lingering subscriptions.
  void dispose() {
    disposeSubscribers();
  }

  /// Executes the mutation with the given variables.
  ///
  /// This function:
  /// 1. Sets the status to pending
  /// 2. Calls the onMutate callback (if provided)
  /// 3. Executes the mutation function
  /// 4. On success: stores data and calls onSuccess callback
  /// 5. On error: stores error and calls onError callback
  /// 6. Always calls onSettled callback
  ///
  /// Concurrent calls are rejected - if a mutation is already pending,
  /// this function will return immediately without doing anything.
  ///
  /// The [mutateAsync] function is often preferred as it allows you to
  /// handle errors with try/catch.
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
      options.onError?.call(error, variables, ctx);
    }
    options.onSettled?.call(data, error, variables, ctx);
  }

  /// Async version of [mutate] that throws on error.
  ///
  /// Similar to [mutate], but:
  /// - Returns the mutation data on success
  /// - Throws the error if the mutation fails
  /// - Returns `null` if the mutation is rejected (already pending)
  ///
  /// This version is useful when you want to use try/catch for error handling
  /// instead of relying on stored mutation error state.
  Future<TData?> mutateAsync(TVariables variables) async {
    if (mutation.isPending) return null;

    this.vars = variables;
    onMutationUpdated();

    dispatch(MutationDispatchAction.mutate, null);

    final ctx = await options.onMutate?.call(variables);
    TData? data;
    TError? error;

    return options.mutationFn(variables).then((TData td) {
      error = null;
      data = td;
      dispatch(MutationDispatchAction.success, data);
      options.onSuccess?.call(td, variables, ctx);
    }).onError((TError err, stack) async {
      data = null;
      error = err;
      dispatch(MutationDispatchAction.error, error);
      options.onError?.call(err, variables, ctx);
      throw err;
    }).whenComplete(() {
      options.onSettled?.call(data, error, variables, ctx);
    }).then((_) {
      return data;
    });
  }

  /// Resets the mutation to its initial idle state.
  ///
  /// Clears stored mutation data and error state and notifies
  /// all subscribers of the state change.
  void reset() {
    dispatch(MutationDispatchAction.reset, null);
  }

  /// Called when the mutation state changes.
  ///
  /// This notifies all subscribers that the mutation state has been updated.
  /// This is typically called after state changes to trigger UI updates.
  void onMutationUpdated() {
    notifyObservers();
  }

  /// Reducer function that applies a [MutationDispatchAction] to the current mutation state.
  ///
  /// This pure function takes the current [Mutation] state and an action,
  /// and returns a new [Mutation] with the updated state.
  ///
  /// Parameters:
  /// - `state`: The current mutation state
  /// - `action`: The action to apply
  /// - `data`: Data associated with the action (error or success data)
  ///
  /// Returns a new [Mutation] with the updated state.
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

  /// Dispatches an action and updates the mutation state.
  ///
  /// This applies the action using the [_reducer] function, updates the
  /// internal [mutation] state, and notifies all subscribers.
  void dispatch(MutationDispatchAction action, dynamic data) {
    mutation = _reducer(mutation, action, data);
    notifyObservers();
  }
}

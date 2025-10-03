import 'dart:async';

import 'package:fquery_core/fquery_core.dart';
import 'package:fquery_core/mutation.dart';

/// A [MutationObserver] is a class which holds a [Mutation] and handles its execution.
class MutationObserver<TData, TError, TVariables, TContext> with Observable {
  /// The options used to configure the mutation.
  late MutationOptions<TData, TError, TVariables, TContext> options;

  /// The mutation instance managed by this observer.
  late Mutation<TData, TError, TVariables, TContext> mutation;

  /// The variables used in the last mutation.
  TVariables? vars;

  /// Creates a new [MutationObserver] instance.
  MutationObserver({
    required MutationOptions<TData, TError, TVariables, TContext> options,
  }) {
    mutation = Mutation<TData, TError, TVariables, TContext>(observer: this);
    _setOptions(options);
  }

  /// Takes a [MutationOptions] and sets the [options] field.
  void _setOptions(
    MutationOptions<TData, TError, TVariables, TContext> options,
  ) {
    this.options = MutationOptions<TData, TError, TVariables, TContext>(
      mutationFn: options.mutationFn,
      onError: options.onError,
      onMutate: options.onMutate,
      onSettled: options.onSettled,
      onSuccess: options.onSuccess,
    );
  }

  void dispose() {
    disposeSubscribers();
  }

  /// This is usually called from the [useMutation] hook
  /// whenever there is any change in the options
  void updateOptions(
    MutationOptions<TData, TError, TVariables, TContext> options,
  ) {
    _setOptions(options);
  }

  /// This is "the" function responsible for the mutation.
  Future<void> mutate(TVariables variables) async {
    if (mutation.state.isPending) return;

    this.vars = variables;
    onMutationUpdated();

    mutation.dispatch(MutationDispatchAction.mutate, null);
    final ctx = await options.onMutate?.call(variables);

    TData? data;
    TError? error;
    try {
      error = null;
      data = await options.mutationFn(variables);
      mutation.dispatch(MutationDispatchAction.success, data);
      options.onSuccess?.call(data as TData, variables, ctx);
    } catch (err) {
      data = null;
      error = err as TError;
      mutation.dispatch(MutationDispatchAction.error, error);
      options.onError?.call(error as TError, variables, ctx);
    }
    options.onSettled?.call(data, error, variables, ctx);
  }

  /// Resets the mutation to its initial state.
  void reset() {
    mutation.dispatch(MutationDispatchAction.reset, null);
  }

  /// This is called from the [Mutation] class whenever the mutation state changes.
  /// It notifies the observer about the change and it also nofities the [useMutation] hook.
  void onMutationUpdated() {
    notifyObservers();
  }
}

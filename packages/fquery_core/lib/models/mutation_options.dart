import 'dart:async';

/// Options for configuring a mutation.
class MutationOptions<TData, TError, TVariables, TContext> {
  /// The mutation function to be executed.
  final Future<TData> Function(TVariables) mutationFn;

  /// Callback function called before the mutation is executed.
  final FutureOr<TContext>? Function(TVariables)? onMutate;

  /// Callback function called if the mutation is successful.
  final void Function(TData, TVariables, TContext?)? onSuccess;

  /// Callback function called if the mutation results in an error.
  final void Function(TError, TVariables, TContext?)? onError;

  /// Callback function called after all other callbacks.
  final void Function(TData?, TError?, TVariables, TContext?)? onSettled;

  /// Creates a new [MutationOptions] instance.
  MutationOptions({
    required this.mutationFn,
    this.onMutate,
    this.onSuccess,
    this.onError,
    this.onSettled,
  });
}

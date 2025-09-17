import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/mutation.dart';
import 'package:fquery/src/mutation_observer.dart';

/// The result of a mutation, including the mutate function and status flags.
class UseMutationResult<TData, TError, TVariables> {
  /// The latest data or error returned by the mutation.
  final TData? data;

  /// The latest error returned by the mutation.
  final TError? error;

  /// Tells if the mutation is idle, i.e. has not been executed yet.
  final bool isIdle;

  /// Tells if the mutation is currently being executed.
  final bool isPending;

  /// Tells if the mutation was successful.
  final bool isSuccess;

  /// Tells if the mutation resulted in an error.
  final bool isError;

  /// The current status of the mutation.
  final MutationStatus status;

  /// The mutate function to trigger the mutation.
  final Future<void> Function(TVariables) mutate;

  /// The time the mutation was last submitted.
  final DateTime? submittedAt;

  /// Resets the mutation state to its initial state.
  final void Function() reset;

  /// The variables used in the last mutation.
  final TVariables? variables;

  /// Creates a new [UseMutationResult] instance.
  UseMutationResult(
      {required this.mutate,
      required this.reset,
      this.status = MutationStatus.idle,
      this.data,
      this.error,
      this.submittedAt,
      this.variables})
      : isIdle = status == MutationStatus.idle,
        isPending = status == MutationStatus.pending,
        isSuccess = status == MutationStatus.success,
        isError = status == MutationStatus.error;
}

/// Options for configuring a mutation.
class UseMutationOptions<TData, TError, TVariables, TContext> {
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

  /// Creates a new [UseMutationOptions] instance.
  UseMutationOptions({
    required this.mutationFn,
    this.onMutate,
    this.onSuccess,
    this.onError,
    this.onSettled,
  });
}

/// Builds a mutation and subscribes to it.
/// Takes a mutation function which either resolves or throws an error.
/// Returns a [UseMutationResult]
/// Example:
/// ```dart
/// final addTodoMutation = useMutation((text) async {
///     return await todosAPI.add(text);
/// });
/// ```

/// You can also pass callback functions like `onSuccess` or `onError` -

/// - `onMutate` - this callback will be called before the mutation is executed and is passed with the same variables the mutation function would receive.
/// - `onSuccess` - this callback will be called if the mutation was successful and receives the result of the mutation as an argument (in addition to the passed variables in the mutation function).
/// - `onError` - this callback will be called if the mutation wassn't successful and receives the error of as an argument (in addition to the passed variables in the mutation function).
/// - `onSettled` - this callback will be called after the mutation has been executed and will receive both the result (if successful) and error(if unsuccessful), in case of success, error will be null and vice-versa.

UseMutationResult<TData, TError, TVariables>
    useMutation<TData, TError, TVariables, TContext>(
  Future<TData> Function(TVariables) mutationFn, {
  final FutureOr<TContext>? Function(TVariables)? onMutate,
  final void Function(TData, TVariables, TContext?)? onSuccess,
  final void Function(TError, TVariables, TContext?)? onError,
  final void Function(TData?, TError?, TVariables, TContext?)? onSettled,
}) {
  final options = useMemoized(
    () => UseMutationOptions(
      mutationFn: mutationFn,
      onMutate: onMutate,
      onSuccess: onSuccess,
      onError: onError,
      onSettled: onSettled,
    ),
    [
      onMutate,
      mutationFn,
      onSuccess,
      onError,
      onSettled,
    ],
  );
  final client = useQueryClient();
  final observer = useMemoized(
    () => MutationObserver<TData, TError, TVariables, TContext>(
      client: client,
      options: options,
    ),
  );

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      observer.updateOptions(options);
    });
    return null;
  }, [observer, options]);

  // This subscribes to the observer
  // and rebuilds the widget on updates.
  useListenable(observer);

  return UseMutationResult(
    data: observer.mutation.state.data,
    error: observer.mutation.state.error,
    status: observer.mutation.state.status,
    mutate: observer.mutate,
    submittedAt: observer.mutation.state.submittedAt,
    reset: observer.reset,
    variables: observer.vars,
  );
}

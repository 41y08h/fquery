import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/mutation.dart';
import 'package:fquery/src/mutation_observer.dart';

class UseMutationResult<TData, TError, TVariables> {
  final TData? data;
  final TError? error;
  final bool isIdle;
  final bool isPending;
  final bool isSuccess;
  final bool isError;
  final MutationStatus status;
  final Future<void> Function(TVariables) mutate;
  final DateTime? submittedAt;
  final void Function() reset;
  final TVariables? variables;

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

class UseMutationOptions<TData, TError, TVariables, TContext> {
  final Future<TData> Function(TVariables) mutationFn;
  final FutureOr<TContext>? Function(TVariables)? onMutate;
  final void Function(TData, TVariables, TContext?)? onSuccess;
  final void Function(TError, TVariables, TContext?)? onError;
  final void Function(TData?, TError?, TVariables, TContext?)? onSettled;

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

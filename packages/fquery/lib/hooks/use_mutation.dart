import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery_core/models/mutation_options.dart';
import 'package:fquery_core/models/mutation_result.dart';
import 'package:fquery_core/observers/mutation_observer.dart';
import 'use_observable.dart';

/// Builds a mutation and subscribes to it.
/// Takes a mutation function which either resolves or throws an error.
/// Returns a [MutationResult]
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

MutationResult<TData, TError, TVariables>
    useMutation<TData, TError, TVariables, TContext>(
  Future<TData> Function(TVariables) mutationFn, {
  final FutureOr<TContext>? Function(TVariables)? onMutate,
  final void Function(TData, TVariables, TContext?)? onSuccess,
  final void Function(TError, TVariables, TContext?)? onError,
  final void Function(TData?, TError?, TVariables, TContext?)? onSettled,
}) {
  final options = useMemoized(
    () => MutationOptions(
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
  final observer = useMemoized(
    () => MutationObserver<TData, TError, TVariables, TContext>(
      options: options,
    ),
  );

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      observer.options = options;
    });
    return null;
  }, [observer, options]);

  // This subscribes to the observer
  // and rebuilds the widget on updates.
  useObservable(observer);

  return MutationResult(
    data: observer.mutation.data,
    error: observer.mutation.error,
    status: observer.mutation.status,
    mutate: observer.mutate,
    submittedAt: observer.mutation.submittedAt,
    reset: observer.reset,
    variables: observer.vars,
  );
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/mutation.dart';
import 'package:fquery/src/mutation_observer.dart';

class UseMutationResult<TVariables, TData, TError> {
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

class UseMutationOptions<TVariables, TData, TError, TContext> {
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

UseMutationResult<TVariables, TData, TError>
    useMutation<TVariables, TData, TError, TContext>(
  Future<TData> Function(TVariables) mutationFn, {
  final FutureOr<TContext>? Function(TVariables)? onMutate,
  final void Function(TData, TVariables, TContext?)? onSuccess,
  final void Function(TError, TVariables, TContext?)? onError,
  final void Function(TData?, TError?, TVariables, TContext?)? onSettled,
}) {
  final options = useMemoized(
    () => UseMutationOptions(
      onMutate: onMutate,
      mutationFn: mutationFn,
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
    () => MutationObserver<TVariables, TData, TError, TContext>(
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

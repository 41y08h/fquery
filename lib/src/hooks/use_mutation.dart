import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/mutation.dart';
import 'package:fquery/src/mutation_observer.dart';

class UseMutationResult<TVariables, TData, TError> {
  final TData? data;
  final DateTime? dataUpdatedAt;
  final TError? error;
  final DateTime? errorUpdatedAt;
  final bool isIdle;
  final bool isLoading;
  final bool isSuccess;
  final bool isError;
  final MutationStatus status;
  final Future<void> Function(TVariables) mutate;

  UseMutationResult({
    required this.data,
    required this.dataUpdatedAt,
    required this.error,
    required this.errorUpdatedAt,
    required this.status,
    required this.mutate,
  })  : isIdle = status == MutationStatus.idle,
        isLoading = status == MutationStatus.loading,
        isSuccess = status == MutationStatus.success,
        isError = status == MutationStatus.error;
}

class UseMutationOptions<TVariables, TData, TError> {
  final void Function(TData)? onMutate;
  final Future<TData> Function(TVariables) mutationFn;
  final void Function(TData, TVariables)? onSuccess;
  final void Function(TError, TVariables)? onError;
  final void Function(TData?, TError?, TVariables)? onSettled;

  UseMutationOptions({
    this.onMutate,
    required this.mutationFn,
    this.onSuccess,
    this.onError,
    this.onSettled,
  });
}

UseMutationResult<TVariables, TData, TError> useMutation<TVariables, TData, TError>({
  void Function(TData)? onMutate,
  required Future<TData> Function(TVariables) mutationFn,
  void Function(TData, TVariables)? onSuccess,
  void Function(TError, TVariables)? onError,
  void Function(TData?, TError?, TVariables)? onSettled,
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
      ]);
  final client = useQueryClient();
  final observer = useMemoized(
      () => MutationObserver<TVariables, TData, TError>(
            client: client,
            options: options,
          ),
      []);

  final mutate = useCallback(
    (TVariables variables) async {
      await observer.mutate(variables);
    },
    [observer],
  );

  // This subscribes to the observer
  // and rebuilds the widget on updates.
  useListenable(observer);

  return UseMutationResult(
    data: observer.mutation.state.data,
    dataUpdatedAt: observer.mutation.state.dataUpdatedAt,
    error: observer.mutation.state.error,
    errorUpdatedAt: observer.mutation.state.errorUpdatedAt,
    status: observer.mutation.state.status,
    mutate: mutate,
  );
}

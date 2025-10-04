import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'mutation.freezed.dart';

enum MutationDispatchAction { reset, mutate, error, success }

enum MutationStatus { idle, pending, success, error }

/// The result of a mutation, including the mutate function and status flags.
class MutationResult<TData, TError, TVariables> {
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

  /// Creates a new [MutationResult] instance.
  MutationResult({
    required this.mutate,
    required this.reset,
    this.status = MutationStatus.idle,
    this.data,
    this.error,
    this.submittedAt,
    this.variables,
  })  : isIdle = status == MutationStatus.idle,
        isPending = status == MutationStatus.pending,
        isSuccess = status == MutationStatus.success,
        isError = status == MutationStatus.error;
}

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

@freezed
abstract class Mutation<TData, TError> with _$Mutation<TData, TError> {
  const Mutation._();

  bool get isIdle => status == MutationStatus.idle;
  bool get isPending => status == MutationStatus.pending;
  bool get isSuccess => status == MutationStatus.success;
  bool get isError => status == MutationStatus.error;

  const factory Mutation({
    TData? data,
    TError? error,
    @Default(MutationStatus.idle) status,
    DateTime? submittedAt,
  }) = _Mutation<TData, TError>;
}

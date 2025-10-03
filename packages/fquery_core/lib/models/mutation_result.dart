import 'dart:async';

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
  }) : isIdle = status == MutationStatus.idle,
       isPending = status == MutationStatus.pending,
       isSuccess = status == MutationStatus.success,
       isError = status == MutationStatus.error;
}

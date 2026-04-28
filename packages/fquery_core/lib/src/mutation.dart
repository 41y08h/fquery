import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'mutation.freezed.dart';

/// Actions that can be dispatched to update a mutation's state.
enum MutationDispatchAction {
  /// Resets the mutation to its initial idle state.
  reset,

  /// Indicates a mutation is starting to execute.
  mutate,

  /// Indicates a mutation encountered an error.
  error,

  /// Indicates a mutation completed successfully.
  success
}

/// The possible states of a mutation.
enum MutationStatus {
  /// The mutation has not been executed yet.
  idle,

  /// The mutation is currently executing.
  pending,

  /// The mutation completed successfully.
  success,

  /// The mutation encountered an error.
  error
}

/// The result of a mutation, including the mutate function and status flags.
///
/// This class encapsulates all information about a mutation's execution state,
/// including the data returned, any errors encountered, and callback functions
/// to trigger or reset the mutation.
class MutationResult<TData, TError, TVariables> {
  /// The latest data returned by the mutation.
  ///
  /// This is `null` until the mutation completes successfully, and remains
  /// `null` if the mutation encounters an error.
  final TData? data;

  /// The latest error encountered by the mutation.
  ///
  /// This is `null` until the mutation encounters an error, and becomes
  /// `null` again when the mutation resets or succeeds.
  final TError? error;

  /// Indicates whether the mutation is in the idle state (not yet executed).
  ///
  /// Returns `true` if [status] is [MutationStatus.idle].
  final bool isIdle;

  /// Indicates whether the mutation is currently executing.
  ///
  /// Returns `true` if [status] is [MutationStatus.pending].
  final bool isPending;

  /// Indicates whether the mutation completed successfully.
  ///
  /// Returns `true` if [status] is [MutationStatus.success].
  final bool isSuccess;

  /// Indicates whether the mutation encountered an error.
  ///
  /// Returns `true` if [status] is [MutationStatus.error].
  final bool isError;

  /// The current status of the mutation.
  ///
  /// Can be one of: [MutationStatus.idle], [MutationStatus.pending],
  /// [MutationStatus.success], or [MutationStatus.error].
  final MutationStatus status;

  /// Function to trigger the mutation with the given variables.
  ///
  /// This function starts the mutation and resolves when the mutation
  /// completes, either successfully or with an error. Errors are caught
  /// and stored in the [error] field rather than thrown.
  ///
  /// If a mutation is already pending, calling this again will be rejected.
  final Future<void> Function(TVariables) mutate;

  /// Async version of the [mutate] function that throws on error.
  ///
  /// Similar to [mutate], but returns the data on success and throws
  /// the error on failure rather than storing it.
  ///
  /// Returns the mutation data on success, or `null` if the mutation
  /// is rejected (already pending).
  final Future<TData?> Function(TVariables) mutateAsync;

  /// The timestamp when the mutation was last submitted.
  ///
  /// This is updated each time [mutate] or [mutateAsync] is called.
  /// Returns `null` if the mutation has never been executed.
  final DateTime? submittedAt;

  /// Function to reset the mutation state to its initial idle state.
  ///
  /// This clears the [data] and [error] fields and resets [status] to idle.
  final void Function() reset;

  /// The variables used in the last mutation execution.
  ///
  /// This remains set after the mutation completes, allowing you to
  /// reference what variables were used. Returns `null` until the first
  /// mutation is executed.
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
    required this.mutateAsync,
  })  : isIdle = status == MutationStatus.idle,
        isPending = status == MutationStatus.pending,
        isSuccess = status == MutationStatus.success,
        isError = status == MutationStatus.error;
}

/// Options for configuring a mutation.
///
/// This class allows you to customize how a mutation behaves and define
/// callbacks to handle different stages of the mutation lifecycle.
///
/// Type parameters:
/// - `TData`: The type of data returned by the mutation on success
/// - `TError`: The type of error thrown by the mutation
/// - `TVariables`: The type of variables passed to the mutation function
/// - `TContext`: The type of context returned by [onMutate]
class MutationOptions<TData, TError, TVariables, TContext> {
  /// The mutation function to be executed.
  ///
  /// This function receives the variables as an argument and should
  /// perform the actual mutation operation (e.g., API call, database update).
  /// Should throw an error of type [TError] if the mutation fails.
  final Future<TData> Function(TVariables) mutationFn;

  /// Callback function called before the mutation is executed.
  ///
  /// This is useful for optimistic updates or preparing context data.
  /// Can be async and can return context data that will be passed to
  /// [onSuccess], [onError], and [onSettled].
  ///
  /// Returns a value of type [TContext] that will be passed to other callbacks.
  final FutureOr<TContext>? Function(TVariables)? onMutate;

  /// Callback function called when the mutation is successful.
  ///
  /// Parameters:
  /// - `data`: The data returned by the mutation
  /// - `variables`: The variables passed to the mutation
  /// - `context`: The context returned by [onMutate], or `null` if [onMutate] was not provided
  final void Function(TData, TVariables, TContext?)? onSuccess;

  /// Callback function called when the mutation results in an error.
  ///
  /// Parameters:
  /// - `error`: The error thrown by the mutation
  /// - `variables`: The variables passed to the mutation
  /// - `context`: The context returned by [onMutate], or `null` if [onMutate] was not provided
  final void Function(TError, TVariables, TContext?)? onError;

  /// Callback function called after all other callbacks.
  ///
  /// This is called regardless of whether the mutation succeeds or fails.
  /// Useful for cleanup operations.
  ///
  /// Parameters:
  /// - `data`: The data returned by the mutation (or `null` if it failed)
  /// - `error`: The error thrown by the mutation (or `null` if it succeeded)
  /// - `variables`: The variables passed to the mutation
  /// - `context`: The context returned by [onMutate], or `null` if [onMutate] was not provided
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

/// Represents the frozen state of a mutation at a point in time.
///
/// This is an immutable data class (using freezed) that captures the current
/// state of a mutation, including its status, data, and error. Use the
/// [copyWith] method to create a new instance with updated fields.
@freezed
abstract class Mutation<TData, TError> with _$Mutation<TData, TError> {
  const Mutation._();

  /// Returns `true` if the mutation is in the idle state.
  bool get isIdle => status == MutationStatus.idle;

  /// Returns `true` if the mutation is currently executing (pending).
  bool get isPending => status == MutationStatus.pending;

  /// Returns `true` if the mutation completed successfully.
  bool get isSuccess => status == MutationStatus.success;

  /// Returns `true` if the mutation encountered an error.
  bool get isError => status == MutationStatus.error;

  /// Creates a new [Mutation] instance.
  ///
  /// All parameters are optional and default to their zero/null values.
  /// Use [copyWith] to create modified copies of existing mutations.
  ///
  /// Parameters:
  /// - `data`: The data returned by the mutation (defaults to `null`)
  /// - `error`: The error encountered by the mutation (defaults to `null`)
  /// - `status`: The current status (defaults to [MutationStatus.idle])
  /// - `submittedAt`: When the mutation was submitted (defaults to `null`)
  const factory Mutation({
    TData? data,
    TError? error,
    @Default(MutationStatus.idle) status,
    DateTime? submittedAt,
  }) = _Mutation<TData, TError>;
}

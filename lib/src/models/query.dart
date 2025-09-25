import 'package:fquery/src/models/query_key.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'query.freezed.dart';

enum DispatchAction {
  fetch,
  error,
  success,
  cancelFetch,
  invalidate,
  refetchSequence,
  refetchError,
}

enum QueryStatus {
  loading,
  success,
  error,
}

enum RefetchOnMount {
  stale,
  always,
  never,
}

abstract class BaseQueryOptions<TData, TError> {
  final QueryKey queryKey;
  final bool enabled;
  final RefetchOnMount refetchOnMount;
  final Duration staleDuration;
  final Duration cacheDuration;
  final Duration? refetchInterval;
  final int retryCount;
  final Duration retryDelay;

  BaseQueryOptions({
    required this.queryKey,
    this.enabled = true,
    this.refetchOnMount = RefetchOnMount.stale,
    this.staleDuration = Duration.zero,
    this.cacheDuration = const Duration(minutes: 5),
    this.refetchInterval,
    this.retryCount = 3,
    this.retryDelay = const Duration(seconds: 1, milliseconds: 500),
  });
}

enum FetchDirection { forward, backward }

class FetchMeta {
  FetchDirection direction;
  FetchMeta({
    required this.direction,
  });

  FetchMeta copyWith({
    FetchDirection? direction,
  }) {
    return FetchMeta(
      direction: direction ?? this.direction,
    );
  }
}

/// State of a query.
@freezed
abstract class Query<TData, TError extends Exception>
    with _$Query<TData, TError> {
  const Query._();

  /// Tells if is fetching for the first time.
  bool get isLoading => status == QueryStatus.loading;

  /// Tells if the query was successful.
  bool get isSuccess => status == QueryStatus.success;

  /// Tells if the query is in error state.
  bool get isError => status == QueryStatus.error;

  /// Creates a new instance of [Query].
  const factory Query(
    QueryKey key, {
    TData? data,
    TError? error,
    DateTime? dataUpdatedAt,
    DateTime? errorUpdatedAt,
    @Default(false) bool isFetching,
    @Default(QueryStatus.loading) QueryStatus status,
    @Default(false) bool isInvalidated,
    FetchMeta? fetchMeta,
    @Default(false) bool isRefetchError,
  }) = _Query<TData, TError>;
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:fquery_core/models/query_key.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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

enum QueryStatus { loading, success, error }

enum RefetchOnMount { stale, always, never }

class QueryOptionsConfigParams {
  // Tells whether the query is enabled
  final bool? enabled;

  /// Specifies the behavior of the query instance when the widget is first built and the data is already available.
  /// - `RefetchOnMount.always` - will always re-fetch when the widget is built.
  /// - `RefetchOnMount.stale` - will fetch the data if it is stale (see `staleDuration`).
  /// - `RefetchOnMount.never` - will never re-fetch.
  final RefetchOnMount? refetchOnMount;
  final Duration? staleDuration;
  final Duration? cacheDuration;
  final Duration? refetchInterval;
  final int? retryCount;
  final Duration? retryDelay;

  QueryOptionsConfigParams({
    this.enabled,
    this.refetchOnMount,
    this.staleDuration,
    this.cacheDuration,
    this.refetchInterval,
    this.retryCount,
    this.retryDelay,
  });
}

class BaseQueryOptions extends QueryOptionsConfigParams {
  final QueryKey queryKey;
  BaseQueryOptions({
    required this.queryKey,
    super.cacheDuration,
    super.enabled,
    super.refetchInterval,
    super.refetchOnMount,
    super.retryCount,
    super.retryDelay,
    super.staleDuration,
  });
}

enum FetchDirection { forward, backward }

class FetchMeta {
  FetchDirection direction;
  FetchMeta({required this.direction});

  FetchMeta copyWith({FetchDirection? direction}) {
    return FetchMeta(direction: direction ?? this.direction);
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

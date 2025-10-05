// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:fquery_core/src/observer.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'query.freezed.dart';

/// The function used to fetch a page of data in an infinite query.
typedef InfiniteQueryFn<TData, TPageParam> = FutureOr<TData> Function(
    TPageParam);

/// Query options
class QueryOptions<TData, TError extends Exception> extends BaseQueryOptions {
  /// The query function used to fetch the data
  final QueryFn<TData> queryFn;

  /// Creates a new [QueryOptions] instance.
  QueryOptions({
    required super.queryKey,
    required this.queryFn,
    super.cacheDuration,
    super.enabled,
    super.refetchInterval,
    super.refetchOnMount,
    super.retryCount,
    super.retryDelay,
    super.staleDuration,
  });
}

enum DispatchAction {
  fetch,
  error,
  success,
  cancelFetch,
  invalidate,
  refetchSequence,
  refetchError,
}

/// The result of a query, including the data, error, status flags, and a refetch function.
class QueryResult<TData, TError> {
  /// The latest data returned by the query, or null if the query has not been successful yet.
  final TData? data;

  /// The time the data was last updated.
  final DateTime? dataUpdatedAt;

  /// The latest error returned by the query, or null if the query has not resulted in an error.
  final TError? error;

  /// The time the error was last updated.
  final DateTime? errorUpdatedAt;

  /// Tells if the query resulted in an error.
  final bool isError;

  /// Tells if the query is currently loading for the first time (no data yet).
  final bool isLoading;

  /// Tells if the query is currently fetching, including background refetches.
  final bool isFetching;

  /// Tells if the query was successful.
  final bool isSuccess;

  /// The current status of the query.
  final QueryStatus status;

  /// The function to manually refetch the query.
  final FutureOr<void> Function() refetch;

  /// Tells if the query has been invalidated and needs to be refetched.
  final bool isInvalidated;

  /// Tells if the last fetch resulted in an error.
  final bool isRefetchError;

  /// Creates a new [QueryResult] instance.
  QueryResult({
    required this.data,
    required this.dataUpdatedAt,
    required this.error,
    required this.errorUpdatedAt,
    required this.isError,
    required this.isLoading,
    required this.isFetching,
    required this.isSuccess,
    required this.status,
    required this.refetch,
    required this.isInvalidated,
    required this.isRefetchError,
  });
}

typedef RawQueryKey = List<Object?>;

/// A serializable, deeply comparable query key.
///
/// Uses `DeepCollectionEquality` for equality and hashing,
/// and `jsonEncode` only for debugging/serialization purposes.
class QueryKey {
  /// The original, user-defined query key.
  final RawQueryKey raw;

  /// Creates a query key from a list of values.
  QueryKey(this.raw);

  static final _equality = DeepCollectionEquality();

  /// The stringified version of the key, for logging/debugging.
  late final String _serialized = jsonEncode(raw);

  /// Returns the serialized representation.
  String get serialized => _serialized;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryKey && _equality.equals(raw, other.raw);

  @override
  int get hashCode => _equality.hash(raw);

  @override
  String toString() => 'QueryKey($serialized)';
}

/// The result of an infinite query, including the data, error, status flags, and a refetch function.
class InfiniteQueryResult<TData, TError extends Exception, TPageParam>
    extends QueryResult<InfiniteQueryData<TData, TPageParam>, TError> {
  /// Tells if the query is currently fetching the next page.
  final bool isFetchingNextPage;

  /// Tells if the query is currently fetching the previous page.
  final bool isFetchingPreviousPage;

  /// Fetches the next page of data.
  final void Function() fetchNextPage;

  /// Fetches the previous page of data.
  final void Function() fetchPreviousPage;

  /// Tells if there is a next page available.
  final bool hasNextPage;

  /// Tells if there is a previous page available.
  final bool hasPreviousPage;

  /// Tells if the query is currently refetching (not counting page fetches).
  final bool isRefetching;

  /// Tells if the last `fetchNextPage` resulted in an error.
  final bool isFetchNextPageError;

  /// Tells if the last `fetchPreviousPage` resulted in an error.
  final bool isFetchPreviousPageError;

  InfiniteQueryResult({
    required super.data,
    required super.dataUpdatedAt,
    required super.error,
    required super.errorUpdatedAt,
    required super.isError,
    required super.isLoading,
    required super.isFetching,
    required super.isSuccess,
    required super.status,
    required void Function() super.refetch,
    required super.isInvalidated,
    required this.isFetchingNextPage,
    required this.isFetchingPreviousPage,
    required this.fetchNextPage,
    required this.fetchPreviousPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.isRefetching,
    required this.isFetchNextPageError,
    required this.isFetchPreviousPageError,
    required super.isRefetchError,
  });
}

class InfiniteQueryOptions<TData, TError, TPageParam> extends BaseQueryOptions {
  /// The query function responsible for fetching the query
  final InfiniteQueryFn<TData, TPageParam> queryFn;

  /// The initial page parameter to start fetching from.
  final TPageParam initialPageParam;

  /// Function to get the next page parameter based on the last page, all pages, last page parameter, and all page parameters.
  final TPageParam? Function(TData, List<TData>, TPageParam, List<TPageParam>)
      getNextPageParam;

  /// Optional function to get the previous page parameter based on the first page, all pages, first page parameter, and all page parameters.
  final TPageParam? Function(TData, List<TData>, TPageParam, List<TPageParam>)?
      getPreviousPageParam;

  /// The maximum number of pages to keep in the cache. If the number of pages exceeds this limit, the oldest page will be removed.
  int? maxPages;

  /// Creates a new instance of [InfiniteQueryOptions].
  InfiniteQueryOptions({
    required super.queryKey,
    required this.queryFn,
    required this.initialPageParam,
    required this.getNextPageParam,
    this.getPreviousPageParam,
    super.cacheDuration,
    super.enabled,
    super.refetchInterval,
    super.refetchOnMount,
    super.retryCount,
    super.retryDelay,
    super.staleDuration,
  });
}

class InfiniteQueryData<TPage, TPageParam> {
  List<TPage> pages;
  List<TPageParam> pageParams;
  InfiniteQueryData({this.pages = const [], this.pageParams = const []});

  InfiniteQueryData<TPage, TPageParam> copyWith({
    List<TPage>? pages,
    List<TPageParam>? pageParams,
  }) {
    return InfiniteQueryData<TPage, TPageParam>(
      pages: pages ?? this.pages,
      pageParams: pageParams ?? this.pageParams,
    );
  }
}

/// Default options for all queries.
class DefaultQueryOptions {
  final bool enabled;

  /// The behavior of the query when the widget is first built and the data is already available.
  final RefetchOnMount refetchOnMount;

  /// The duration until the data becomes stale.
  final Duration staleDuration;

  /// The duration until the data is removed from the cache.
  final Duration cacheDuration;

  /// The interval at which the query will be refetched.
  final Duration? refetchInterval;

  /// The number of retry attempts if the query fails.
  final int retryCount;

  /// The delay between retry attempts if the query fails.
  final Duration retryDelay;

  /// Creates a new [DefaultQueryOptions] instance.
  DefaultQueryOptions({
    this.enabled = true,
    this.refetchOnMount = RefetchOnMount.stale,
    this.staleDuration = Duration.zero,
    this.cacheDuration = const Duration(seconds: 5),
    this.refetchInterval,
    this.retryCount = 3,
    this.retryDelay = const Duration(seconds: 1, milliseconds: 500),
  });
}

enum QueryStatus { loading, success, error }

enum RefetchOnMount { stale, always, never }

abstract class BaseQueryOptions {
  final QueryKey queryKey;

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

  BaseQueryOptions({
    required this.queryKey,
    this.enabled,
    this.refetchOnMount,
    this.staleDuration,
    this.cacheDuration,
    this.refetchInterval,
    this.retryCount,
    this.retryDelay,
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

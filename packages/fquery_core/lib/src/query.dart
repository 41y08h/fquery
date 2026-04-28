// ignore_for_file: sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:fquery_core/src/observer.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'query.freezed.dart';

/// The function used to fetch a page of data in an infinite query.
typedef InfiniteQueryFn<TData, TPageParam> = FutureOr<TData> Function(
    TPageParam);

/// Options used to create or update a single query observer.
///
/// Values left as `null` fall back to the [DefaultQueryOptions] configured on
/// the query cache.
class QueryOptions<TData, TError extends Exception>
    extends BaseQueryOptions<TData, TError> {
  /// The function used to fetch the query data.
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

/// Actions used internally to transition query state.
enum DispatchAction {
  /// Marks a query as fetching.
  fetch,

  /// Stores an initial-load error.
  error,

  /// Stores successful query data.
  success,

  /// Cancels the current fetch.
  cancelFetch,

  /// Marks a query as invalidated.
  invalidate,

  /// Stores a page while an infinite query refetch sequence is still running.
  refetchSequence,

  /// Stores an error from a background refetch.
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

/// The user-facing representation of a query key.
typedef RawQueryKey = List<Object?>;

/// A serializable, deeply comparable query key.
///
/// Uses `DeepCollectionEquality` for equality and hashing,
/// and `jsonEncode` only for debugging/serialization purposes.
class QueryKey<TData, TError extends Exception> {
  /// The original, user-defined query key.
  final RawQueryKey raw;

  /// Creates a query key from a list of JSON-encodable values.
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

/// The result of an infinite query.
///
/// Extends [QueryResult] with page navigation helpers and status flags for
/// forward and backward page fetches.
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

  /// Creates a new [InfiniteQueryResult] instance.
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

/// Options used to create or update an infinite query observer.
///
/// Infinite queries store data as ordered pages and use page parameters to
/// decide how to fetch the next or previous page.
class InfiniteQueryOptions<TData, TError extends Exception, TPageParam>
    extends BaseQueryOptions<InfiniteQueryData<TData, TPageParam>, TError> {
  /// The query function responsible for fetching the query
  final InfiniteQueryFn<TData, TPageParam> queryFn;

  /// The initial page parameter to start fetching from.
  final TPageParam initialPageParam;

  /// Function that returns the next page parameter.
  ///
  /// Receives the last page, all pages, the last page parameter, and all page
  /// parameters. Return `null` when there is no next page.
  final TPageParam? Function(TData, List<TData>, TPageParam, List<TPageParam>)
      getNextPageParam;

  /// Function that returns the previous page parameter.
  ///
  /// Receives the first page, all pages, the first page parameter, and all page
  /// parameters. Return `null` when there is no previous page.
  final TPageParam? Function(TData, List<TData>, TPageParam, List<TPageParam>)?
      getPreviousPageParam;

  /// The maximum number of pages to keep in the cache.
  ///
  /// When this limit is reached, fetching a new forward page removes the first
  /// page, and fetching a new backward page removes the last page.
  final int? maxPages;

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
    this.maxPages,
  });
}

/// Data stored by an infinite query.
///
/// [pages] contains the fetched page values in order. [pageParams] contains the
/// page parameter used to fetch each page at the same index.
class InfiniteQueryData<TPage, TPageParam> {
  /// The fetched pages, ordered from first to last.
  List<TPage> pages;

  /// The page parameters corresponding to [pages].
  List<TPageParam> pageParams;

  /// Creates a new [InfiniteQueryData] instance.
  InfiniteQueryData({this.pages = const [], this.pageParams = const []});

  /// Returns a copy with the provided fields replaced.
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
  /// Whether queries are enabled by default.
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

/// The high-level lifecycle status of a query.
enum QueryStatus {
  /// The query has no successful data yet and is loading.
  loading,

  /// The query completed successfully.
  success,

  /// The query encountered an error.
  error,
}

/// Controls whether cached data should be refetched when an observer mounts.
enum RefetchOnMount {
  /// Refetch only when cached data is stale.
  stale,

  /// Always refetch when an observer mounts.
  always,

  /// Never refetch solely because an observer mounted.
  never,
}

/// Shared query options used by single and infinite query observers.
abstract class BaseQueryOptions<TData, TError extends Exception> {
  /// The key that identifies the query in the cache.
  final QueryKey<TData, TError> queryKey;

  /// Whether the query is allowed to fetch.
  final bool? enabled;

  /// Specifies how an observer behaves on mount when cached data already exists.
  ///
  /// - `RefetchOnMount.always` - will always re-fetch when the widget is built.
  /// - `RefetchOnMount.stale` - will fetch the data if it is stale (see `staleDuration`).
  /// - `RefetchOnMount.never` - will never re-fetch.
  final RefetchOnMount? refetchOnMount;

  /// Duration after which successful query data is considered stale.
  final Duration? staleDuration;

  /// Duration to retain unused query data in the cache.
  final Duration? cacheDuration;

  /// Interval used for automatic refetching.
  final Duration? refetchInterval;

  /// Number of retry attempts after a failed fetch.
  final int? retryCount;

  /// Delay between retry attempts.
  final Duration? retryDelay;

  /// Creates shared query options.
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

/// Direction of an infinite query page fetch.
enum FetchDirection {
  /// Fetching a page after the current last page.
  forward,

  /// Fetching a page before the current first page.
  backward,
}

/// Metadata associated with an in-flight query fetch.
class FetchMeta {
  /// The direction of an infinite query page fetch.
  FetchDirection direction;

  /// Creates fetch metadata for the given [direction].
  FetchMeta({required this.direction});

  /// Returns a copy with the provided fields replaced.
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

  /// Creates a new query state snapshot.
  ///
  /// [key] identifies the query in the cache. The remaining fields describe the
  /// latest data, error, timestamps, fetch metadata, and lifecycle flags.
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

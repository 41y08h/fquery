import 'package:fquery/src/infinite_query_observer.dart';
import 'package:fquery/src/query.dart';
import 'package:fquery/src/query_key.dart';

class InfiniteQueryConfig<TData, TError extends Exception, TPageParam> {
  /// The query key used to identify the query.
  final RawQueryKey queryKey;

  /// The function that fetches the data for the query.
  final InfiniteQueryFn<TData, TPageParam> queryFn;

  /// The initial page param to be used for the first page
  final TPageParam initialPageParam;

  /// Function to get the next page param
  final TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  ) getNextPageParam;

  /// Function to get the previous page param
  final TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  )? getPreviousPageParam;

  /// Maximum number of pages to keep in the cache
  final int? maxPages;

  /// Whether the query is enabled or not
  final bool enabled;

  /// Refetch behavior when the widget is mounted
  final RefetchOnMount? refetchOnMount;

  /// The duration until the data becomes stale.
  final Duration? staleDuration;

  /// The duration until the data is removed from the cache.
  final Duration? cacheDuration;

  /// The interval at which the query will be refetched.
  final Duration? refetchInterval;

  /// The number of retry attempts if the query fails.
  final int? retryCount;

  /// The delay between retry attempts if the query fails.
  final Duration? retryDelay;

  const InfiniteQueryConfig({
    required this.queryKey,
    required this.queryFn,
    required this.initialPageParam,
    required this.getNextPageParam,
    this.getPreviousPageParam,
    this.maxPages,
    this.enabled = true,
    this.refetchOnMount,
    this.staleDuration,
    this.cacheDuration,
    this.refetchInterval,
    this.retryCount,
    this.retryDelay,
  });

  InfiniteQueryConfig<TData, TError, TPageParam> copyWith({
    RawQueryKey? queryKey,
    InfiniteQueryFn<TData, TPageParam>? queryFn,
    TPageParam? initialPageParam,
    TPageParam? Function(
      TData,
      List<TData>,
      TPageParam,
      List<TPageParam>,
    )? getNextPageParam,
    TPageParam? Function(
      TData,
      List<TData>,
      TPageParam,
      List<TPageParam>,
    )? getPreviousPageParam,
    int? maxPages,
    bool? enabled,
    RefetchOnMount? refetchOnMount,
    Duration? staleDuration,
    Duration? cacheDuration,
    Duration? refetchInterval,
    int? retryCount,
    Duration? retryDelay,
  }) {
    return InfiniteQueryConfig<TData, TError, TPageParam>(
      queryKey: queryKey ?? this.queryKey,
      queryFn: queryFn ?? this.queryFn,
      initialPageParam: initialPageParam ?? this.initialPageParam,
      getNextPageParam: getNextPageParam ?? this.getNextPageParam,
      getPreviousPageParam: getPreviousPageParam ?? this.getPreviousPageParam,
      maxPages: maxPages ?? this.maxPages,
      enabled: enabled ?? this.enabled,
      refetchOnMount: refetchOnMount ?? this.refetchOnMount,
      staleDuration: staleDuration ?? this.staleDuration,
      cacheDuration: cacheDuration ?? this.cacheDuration,
      refetchInterval: refetchInterval ?? this.refetchInterval,
      retryCount: retryCount ?? this.retryCount,
      retryDelay: retryDelay ?? this.retryDelay,
    );
  }
}

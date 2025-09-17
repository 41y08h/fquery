import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/infinite_query_observer.dart';
import 'package:fquery/src/query_key.dart';

/// A Builder widget which uses [useInfiniteQuery] internally
class InfiniteQueryBuilder<TData, TError extends Exception, TPageParam>
    extends HookWidget {
  /// The builder function which recevies the [UseInfiniteQueryResult] along with the [BuildContext]
  final Widget Function(
      BuildContext, UseInfiniteQueryResult<TData, TError, TPageParam>) builder;

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

  /// Creates a new [InfiniteQueryBuilder] instance.
  const InfiniteQueryBuilder(
    this.queryKey,
    this.queryFn, {
    super.key,
    required this.builder,
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

  @override
  Widget build(BuildContext context) {
    final query = useInfiniteQuery<TData, TError, TPageParam>(
      queryKey,
      queryFn,
      initialPageParam: initialPageParam,
      getNextPageParam: getNextPageParam,
      getPreviousPageParam: getPreviousPageParam,
      maxPages: maxPages,
      enabled: enabled,
      refetchOnMount: refetchOnMount,
      staleDuration: staleDuration,
      cacheDuration: cacheDuration,
      refetchInterval: refetchInterval,
      retryCount: retryCount,
      retryDelay: retryDelay,
    );

    return Builder(builder: (context) {
      return builder(context, query);
    });
  }
}

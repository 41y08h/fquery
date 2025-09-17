import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/observer.dart';
import 'package:fquery/src/query_key.dart';

/// A Builder widget which uses [useQuery] internally
class QueryBuilder<TData, TError extends Exception> extends HookWidget {
  /// The builder function which recevies the [UseQueryResult] along with the [BuildContext]
  final Widget Function(BuildContext, UseQueryResult<TData, TError>) builder;

  /// The query key used to identify the query.
  final RawQueryKey queryKey;

  /// The function that fetches the data for the query.
  final QueryFn<TData> queryFn;

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

  /// Creates a new [QueryBuilder] instance.
  const QueryBuilder(
    this.queryKey,
    this.queryFn, {
    super.key,
    required this.builder,
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
    final query = useQuery<TData, TError>(
      queryKey,
      queryFn,
      cacheDuration: cacheDuration,
      enabled: enabled,
      refetchInterval: refetchInterval,
      refetchOnMount: refetchOnMount,
      staleDuration: staleDuration,
      retryCount: retryCount,
      retryDelay: retryDelay,
    );

    return Builder(builder: (context) {
      return builder(context, query);
    });
  }
}

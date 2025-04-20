import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/infinite_query_observer.dart';
import 'package:fquery/src/query.dart';

class InfiniteQueryBuilder<TData, TError, TPageParam> extends HookWidget {
  final Widget Function(
      BuildContext, UseInfiniteQueryResult<TData, TError, TPageParam>) builder;
  final QueryKeyParameter queryKey;
  final InfiniteQueryFn<TData, TPageParam> queryFn;
  final TPageParam initialPageParam;

  final TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  ) getNextPageParam;
  final TPageParam? Function(
    TData,
    List<TData>,
    TPageParam,
    List<TPageParam>,
  )? getPreviousPageParam;

  final int? maxPages;
  final bool enabled;
  final RefetchOnMount? refetchOnMount;
  final Duration? staleDuration;
  final Duration? cacheDuration;
  final Duration? refetchInterval;
  final int? retryCount;
  final Duration? retryDelay;

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

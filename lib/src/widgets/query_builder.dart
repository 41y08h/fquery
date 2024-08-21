import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/observer.dart';
import 'package:fquery/src/query.dart';

class QueryBuilder<TData, TError> extends HookWidget {
  final Widget Function(BuildContext, UseQueryResult<TData, TError>) builder;
  final QueryKey queryKey;
  final QueryFn<TData> queryFn;
  final bool enabled;

  final RefetchOnMount? refetchOnMount;
  final Duration? staleDuration;
  final Duration? cacheDuration;
  final Duration? refetchInterval;
  final int? retryCount;
  final Duration? retryDelay;

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

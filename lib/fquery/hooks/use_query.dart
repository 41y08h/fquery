import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/fquery.dart';

enum RefetchOnMount {
  stale,
  always,
  never,
}

QueryState<TData, TError> useQuery<TData, TError>(
  String queryKey,
  Future<TData> Function() fetcher, {
  bool enabled = true,
  Duration? refreshDuration,
  RefetchOnMount refetchOnMount = RefetchOnMount.stale,
}) {
  final client = useQueryClient();
  final query = useListenable(client.buildQuery<TData, TError>(queryKey));

  final fetch = useCallback(() async {
    if (!enabled || query.state.isFetching) {
      return;
    }

    query.setIsFetching(true);
    try {
      final data = await fetcher();
      query.setData(data);
    } catch (e) {
      query.setError(e as TError);
    } finally {
      query.setIsFetching(false);
    }
  }, [query, enabled, refreshDuration]);

  useEffect(() {
    final isRefetching = query.state.status != QueryStatus.loading;
    if (isRefetching) {
      switch (refetchOnMount) {
        case RefetchOnMount.stale:
          break;
        case RefetchOnMount.never:
          return;
        default:
          break;
      }
    }
    fetch();
    return null;
  }, [fetch]);

  useEffect(() {
    if (refreshDuration == null) return null;

    final timer = Timer.periodic(refreshDuration, (timer) {
      fetch();
    });
    return () => timer.cancel();
  }, [refreshDuration, fetch]);

  return query.state;
}

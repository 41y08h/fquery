import 'package:fquery/src/query_cache.dart';
import 'query.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class DefaultQueryOptions {
  RefetchOnMount refetchOnMount;
  Duration staleDuration;
  Duration cacheDuration;
  Duration? refetchInterval;

  DefaultQueryOptions({
    this.refetchOnMount = RefetchOnMount.stale,
    this.staleDuration = Duration.zero,
    this.cacheDuration = const Duration(minutes: 5),
    this.refetchInterval,
  });
}

class QueryClient {
  final QueryCache queryCache = QueryCache();
  late DefaultQueryOptions defaultQueryOptions;

  QueryClient({DefaultQueryOptions? defaultQueryOptions}) {
    this.defaultQueryOptions = defaultQueryOptions ?? DefaultQueryOptions();
  }

  void setQueryData<TData>(
      QueryKey queryKey, TData Function(TData? previous) updater) {
    final query = queryCache.get(queryKey);
    query?.dispatch(DispatchAction.success, updater(query.state.data));
  }

  void invalidateQueries(QueryKey key, {bool exact = false}) {
    queryCache.queries.forEach((queryKey, query) {
      if (exact) {
        if (queryKey == key.lock) {
          query.dispatch(DispatchAction.invalidate, null);
        }
      } else {
        final isPartialMatch = queryKey.length >= key.length &&
            queryKey.sublist(0, key.length) == key.lock;

        if (isPartialMatch) {
          query.dispatch(DispatchAction.invalidate, null);
        }
      }
    });
  }
}

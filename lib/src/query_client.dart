import 'package:fquery/src/query_cache.dart';
import 'query.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

class DefaultQueryOptions {
  final RefetchOnMount refetchOnMount;
  final Duration staleDuration;
  final Duration cacheDuration;
  final Duration? refetchInterval;
  final int retryCount;
  final Duration retryDelay;

  DefaultQueryOptions({
    this.refetchOnMount = RefetchOnMount.stale,
    this.staleDuration = Duration.zero,
    this.cacheDuration = const Duration(minutes: 5),
    this.refetchInterval,
    this.retryCount = 3,
    this.retryDelay = const Duration(seconds: 1, milliseconds: 500),
  });
}

/// It is used to interact with the query cache.
/// Can also be used to configure queries on a global basis
/// using [DefaultQueryOptions].
class QueryClient {
  final QueryCache queryCache = QueryCache();
  late DefaultQueryOptions defaultQueryOptions;

  QueryClient({DefaultQueryOptions? defaultQueryOptions}) {
    this.defaultQueryOptions = defaultQueryOptions ?? DefaultQueryOptions();
  }

  /// Sets the query cache idendifiable by the given query key.
  /// If the query data doesn't exist already in the cache (that's why `previous` is nullable),
  /// it'll be created.
  /// The type of returned data from the updater function
  /// must match the type of data stored in the cache,
  /// otherwise an error will be thrown.
  ///
  /// Example:
  /// ```dart
  /// queryClient.setQueryData<List<Post>>(['posts'], (previous) {
  ///   return previous?.map((post) {
  ///     return post.copyWith(
  ///       title: "lorem ipsum"
  ///     );
  ///   }).toList() ?? <Post>[]
  /// })
  /// ```
  void setQueryData<TData>(
      QueryKeyParameter queryKey, TData Function(TData? previous) updater) {
    final query =
        queryCache.build<TData, dynamic>(queryKey: queryKey, client: this);
    query.dispatch(DispatchAction.success, updater(query.state.data));
  }

  TData? getQueryData<TData>(QueryKeyParameter queryKey) {
    try {
      final query = queryCache.get<TData, dynamic>(queryKey);
      return query.state.data;
    } catch (e) {
      return null as TData?;
    }
  }

  /// Marks the query as stale.
  /// If the query is being used in a widget, it will be refetched,
  /// otherwise it will be refetched when it is used by a widget at a later point in time.
  /// Supports partial matching, take a look at the exact option.
  ///
  /// Example:
  /// ```dart
  /// final queryClient = useQueryClient();
  ///
  /// // Invalidate every query with a key that starts with `post`
  /// queryClient.invalidateQueries(['posts']);
  ///
  /// // Both queries will be invalidated
  /// final posts = useQuery(['posts'], getPosts);
  /// final post = useQuery(['posts', 1], getPosts);
  ///
  /// // Use `exact: true` to exactly match the query
  /// queryClient.invalidateQueries(['posts'], exact: true);
  ///
  /// // Only this will invalidate
  /// final posts = useQuery(['posts'], getPosts);
  /// ```
  void invalidateQueries(QueryKeyParameter key, {bool exact = false}) {
    queryCache.queries.forEach((queryKey, query) {
      void action() {
        query.dispatch(DispatchAction.invalidate, null);
      }

      if (exact) {
        if (queryKey.serialized == QueryKey(key).serialized) action();
      } else {
        final isPartialMatch = queryKey.raw.length >= key.length &&
            QueryKey(queryKey.raw.sublist(0, key.length)) == QueryKey(key);

        if (isPartialMatch) action();
      }
    });
  }

  void removeQueries(QueryKeyParameter key, {bool exact = false}) {
    queryCache.queries.forEach((queryKey, query) {
      void action() {
        Future.delayed(Duration.zero, () {
          queryCache.remove(query);
        });
      }

      if (exact) {
        if (queryKey.serialized == QueryKey(key).serialized) action();
      } else {
        final isPartialMatch = queryKey.raw.length >= key.length &&
            QueryKey(queryKey.raw.sublist(0, key.length)) == QueryKey(key);

        if (isPartialMatch) action();
      }
    });
  }

  int isFetching() {
    return queryCache.queries.entries
        .where((queryMap) => queryMap.value.state.isFetching)
        .length;
  }
}

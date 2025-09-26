import 'dart:async';
import 'package:fquery/src/models/query.dart';
import 'package:fquery/src/models/query_options.dart';
import 'package:fquery/src/observable.dart';
import 'package:fquery/src/observers/observer.dart';

/// A function that fetches data for a query.
typedef QueryFn<TData> = Future<TData> Function();

/// An observer is a class which subscribes to a query and updates its state when the query changes.
/// It is responsible for fetching the query and updating the cache.
/// There can be multiple observers for the same query and hence
/// sharing the same piece of data throughout the whole application.
class QueryObserver<TData, TError extends Exception>
    extends Observer<TData, TError, QueryOptions<TData, TError>>
    with Observable {
  @override
  Query<TData, TError> get query {
    return client.queryCache.get(options.queryKey);
  }

  /// Creates a new [QueryObserver] instance.
  QueryObserver({
    required super.client,
    required super.options,
    super.listen = true,
  }) {
    client.queryCache.build<TData, TError>(
      queryKey: options.queryKey,
      client: client,
      observer: listen ? this : null,
    );
  }

  @override
  void initialize() {
    // Initiate query on mount
    if (options.enabled == false) return;
    final isRefetching = !query.isLoading;
    final isInvalidated = query.isInvalidated;

    // [RefetchOnMount] behaviour is specified here
    if (isRefetching && !isInvalidated) {
      switch (options.refetchOnMount) {
        case RefetchOnMount.always:
          fetch();
          break;
        case RefetchOnMount.stale:
          DateTime? staleAt = query.dataUpdatedAt?.add(options.staleDuration);
          final isStale = staleAt?.isBefore(DateTime.now()) ?? true;
          if (isStale) fetch();
          break;
        case RefetchOnMount.never:
          break;
      }
    } else {
      fetch();
    }
  }

  @override
  void updateOptions(QueryOptions<TData, TError> options) {
    // Changes for side effects:
    // [options.enabled]
    // [options.refetchInterval]

    final refetchIntervalChanged =
        this.options.refetchInterval != options.refetchInterval;
    final isEnabledChanged = this.options.enabled != options.enabled;

    this.options = options;

    if (isEnabledChanged) {
      if (options.enabled) {
        fetch();
      } else {
        resolver.cancel();
        refetchTimer?.cancel();
      }
    }

    if (refetchIntervalChanged) {
      // Schedules the next fetch if the [options.refetchInterval] is set.
      if (options.refetchInterval != null) {
        scheduleRefetch();
      } else {
        refetchTimer?.cancel();
      }
    }
  }

  /// This is "the" function responsible for fetching the query.
  Future<void> fetch() async {
    if (!options.enabled || query.isFetching) {
      return;
    }

    final isRefetching = !query.isLoading;

    client.queryCache.dispatch(query.key, DispatchAction.fetch, null);
    // Important: State change, then any other
    // function invocation in the following callbacks
    await resolver.resolve<TData>(
      options.queryFn,
      retryCount: options.retryCount,
      retryDelay: options.retryDelay,
      onResolve: (data) {
        client.queryCache.dispatch(query.key, DispatchAction.success, data);
      },
      onError: (error) {
        final action =
            isRefetching ? DispatchAction.refetchError : DispatchAction.error;
        client.queryCache.dispatch(query.key, action, error);
      },
      onCancel: () {
        client.queryCache.dispatch(query.key, DispatchAction.cancelFetch, null);
      },
    );
  }

  @override
  void onQueryCacheNotification() {
    notifyListeners();
    if (query.isInvalidated) {
      fetch();
    }
  }
}

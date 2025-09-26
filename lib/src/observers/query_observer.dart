import 'dart:async';
import 'package:fquery/src/models/query.dart';
import 'package:fquery/src/models/query_options.dart';
import 'package:fquery/src/observable.dart';
import 'package:fquery/src/observers/observer.dart';
import '../query_client.dart';
import '../retry_resolver.dart';

/// A function that fetches data for a query.
typedef QueryFn<TData> = Future<TData> Function();

/// An observer is a class which subscribes to a query and updates its state when the query changes.
/// It is responsible for fetching the query and updating the cache.
/// There can be multiple observers for the same query and hence
/// sharing the same piece of data throughout the whole application.
class QueryObserver<TData, TError extends Exception>
    with Observable, Observer<TData, TError, QueryOptions<TData, TError>> {
  /// Query to which the observer is subscribed to
  Query<TData, TError> get query {
    return client.queryCache.get(options.queryKey);
  }

  final _resolver = RetryResolver();
  Timer? _refetchTimer;

  /// Creates a new [QueryObserver] instance.
  QueryObserver({
    required QueryClient client,
    required QueryOptions<TData, TError> options,
  }) {
    this.client = client;
    this.options = options;
    client.queryCache.build<TData, TError>(
      queryKey: options.queryKey,
      client: client,
      observer: this,
    );
    client.queryCache.addListener(hashCode, _onQueryUpdated);
  }

  /// Starts the initial fetch routine
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

  /// Updates the options and produces the required side effects
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
        _resolver.cancel();
        _refetchTimer?.cancel();
      }
    }

    if (refetchIntervalChanged) {
      // Schedules the next fetch if the [options.refetchInterval] is set.
      if (options.refetchInterval != null) {
        _scheduleRefetch();
      } else {
        _refetchTimer?.cancel();
        _refetchTimer = null;
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
    await _resolver.resolve<TData>(
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

  void _onQueryUpdated() {
    notifyListeners();
    if (query.isInvalidated) {
      fetch();
    }
  }

  /// Disposes the observer
  void dispose() {
    client.queryCache.removeListener(hashCode);
    client.queryCache.dismantle(this);
    _resolver.cancel();
    _refetchTimer?.cancel();
  }

  /// Schedules the next fetch if the [options.refetchInterval] is set.
  void _scheduleRefetch() {
    if (options.refetchInterval == null) return;
    _refetchTimer?.cancel();
    _refetchTimer = Timer(options.refetchInterval as Duration, fetch);
  }
}

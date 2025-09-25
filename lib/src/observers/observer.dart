import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:fquery/src/hooks/use_query.dart';
import 'package:fquery/src/models/query.dart';
import 'package:fquery/src/models/query_options.dart';
import '../query_client.dart';
import '../retry_resolver.dart';

/// A function that fetches data for a query.
typedef QueryFn<TData> = Future<TData> Function();

/// An observer is a class which subscribes to a query and updates its state when the query changes.
/// It is responsible for fetching the query and updating the cache.
/// There can be multiple observers for the same query and hence
/// sharing the same piece of data throughout the whole application.
class Observer<TData, TError extends Exception> extends ChangeNotifier {
  /// The query client used to manage the query.
  final QueryClient client;

  /// The query instance managed by this observer.
  late final Query<TData, TError> query;

  /// The options used to configure the query.
  late QueryOptions<TData, TError> options;

  final _resolver = RetryResolver();
  Timer? _refetchTimer;

  /// Creates a new [Observer] instance.
  Observer({
    required this.client,
    required this.options,
  }) {
    query = client.queryCache.build<TData, TError>(
      queryKey: options.queryKey,
      client: client,
    );
    // query.setCacheDuration(this.options.cacheDuration);
  }

  /// This is called from the [useQuery] hook
  /// whenever the first widget build is done
  void initialize() {
    // Subcribe to any query state changes
    client.queryCache.addListener(_onQueryUpdated);

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

  /// This is usually called from the [useQuery] hook
  /// whenever there is any change in the options
  void updateOptions(QueryOptions<TData, TError> options) {
    // Compare variable changes before calling `_setOptions`
    final refetchIntervalChanged =
        this.options.refetchInterval != options.refetchInterval;
    final isEnabledChanged = this.options.enabled != options.enabled;

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
        scheduleRefetch();
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
  @override
  void dispose() {
    client.queryCache.removeListener(_onQueryUpdated);
    _resolver.cancel();
    _refetchTimer?.cancel();
    super.dispose();
  }

  /// Schedules the next fetch if the [options.refetchInterval] is set.
  void scheduleRefetch() {
    if (options.refetchInterval == null) return;
    _refetchTimer?.cancel();
    _refetchTimer = Timer(options.refetchInterval as Duration, fetch);
  }
}

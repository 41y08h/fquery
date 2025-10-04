import 'dart:async';

import 'package:fquery_core/models/query.dart';
import 'package:fquery_core/models/query_key.dart';
import 'package:fquery_core/observable.dart';
import 'package:fquery_core/query_cache.dart';

abstract class Observer<TData, TError extends Exception,
    TOptions extends BaseQueryOptions> with Observable {
  /// Tells if it is listening to notifications from query cache
  late final bool listenToQueryCache;

  late final QueryCache cache;

  Timer? _refetchTimer;

  final QueryKey queryKey;
  // Tells whether the query is enabled
  late bool enabled;

  /// Specifies the behavior of the query instance when the widget is first built and the data is already available.
  /// - `RefetchOnMount.always` - will always re-fetch when the widget is built.
  /// - `RefetchOnMount.stale` - will fetch the data if it is stale (see `staleDuration`).
  /// - `RefetchOnMount.never` - will never re-fetch.
  late RefetchOnMount refetchOnMount;
  late Duration staleDuration;
  late Duration cacheDuration;
  late Duration? refetchInterval;
  late int retryCount;
  late Duration retryDelay;

  /// Query to which the observer is subscribed to
  Query get query;

  Observer({
    required this.queryKey,
    required this.cache,
    required this.enabled,
    required this.refetchOnMount,
    required this.staleDuration,
    required this.cacheDuration,
    required this.refetchInterval,
    required this.retryCount,
    required this.retryDelay,
    required this.listenToQueryCache,
  });

  void setOptions(TOptions options) {
    enabled = options.enabled ?? cache.defaultQueryOptions.enabled;
    refetchOnMount =
        options.refetchOnMount ?? cache.defaultQueryOptions.refetchOnMount;
    staleDuration =
        options.staleDuration ?? cache.defaultQueryOptions.staleDuration;
    cacheDuration =
        options.cacheDuration ?? cache.defaultQueryOptions.cacheDuration;
    refetchInterval =
        options.refetchInterval ?? cache.defaultQueryOptions.refetchInterval;
    retryCount = options.retryCount ?? cache.defaultQueryOptions.retryCount;
    retryDelay = options.retryDelay ?? cache.defaultQueryOptions.retryDelay;
  }

  /// Callback function for receiving notifications
  /// from the query cache, typically when query is updated
  void onQueryCacheNotification();

  /// The function responsible for fetching the data
  Future<void> fetch();

  /// Updates the options and produces any side effects required
  void updateOptions(TOptions newOptions);

  /// Starts the initial fetch routine
  void initialize();

  /// Disposes the observer
  void dispose() {
    _refetchTimer?.cancel();
  }

  /// Schedules the next fetch if the [options.refetchInterval] is set.
  void scheduleRefetch() {
    if (refetchInterval == null) return;
    _refetchTimer?.cancel();
    _refetchTimer = Timer(refetchInterval as Duration, fetch);
  }

  /// Cancels any scheduled refetch
  void cancelRefetch() {
    _refetchTimer?.cancel();
  }
}

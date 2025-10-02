import 'dart:async';

import 'package:fquery/src/core/models/query.dart';
import 'package:fquery/src/core/observable.dart';
import 'package:fquery/src/core/query_client.dart';

abstract class Observer<TData, TError extends Exception,
    TOptions extends BaseQueryOptions<TData, TError>> with Observable {
  /// Query client the observer is subscribed to
  late final QueryClient client;

  /// Tells if it is listening to notifications from query cache
  late final bool listenToQueryCache;

  /// Options for the query
  late TOptions options;

  Timer? _refetchTimer;

  /// Query to which the observer is subscribed to
  Query get query;

  Observer({
    required this.client,
    required this.options,
    required this.listenToQueryCache,
  });

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
    client.queryCache.unsubscribe(hashCode);
    client.queryCache.dismantle(this);
    _refetchTimer?.cancel();
  }

  /// Schedules the next fetch if the [options.refetchInterval] is set.
  void scheduleRefetch() {
    if (options.refetchInterval == null) {
      print('no refetch, bye');
    }
    if (options.refetchInterval == null) return;
    _refetchTimer?.cancel();
    _refetchTimer = Timer(options.refetchInterval as Duration, fetch);
  }

  /// Cancels any scheduled refetch
  void cancelRefetch() {
    _refetchTimer?.cancel();
  }
}

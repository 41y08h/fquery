import 'dart:async';

import 'package:fquery/src/models/query.dart';
import 'package:fquery/src/observable.dart';
import 'package:fquery/src/query_client.dart';
import 'package:fquery/src/retry_resolver.dart';

abstract class Observer<TData, TError extends Exception,
    TOptions extends BaseQueryOptions<TData, TError>> with Observable {
  /// Query client the observer is subscribed to
  late final QueryClient client;

  /// Options for the query
  late TOptions options;

  final _resolver = RetryResolver();
  Timer? _refetchTimer;

  /// Query to which the observer is subscribed to
  Query get query;
  RetryResolver get resolver => _resolver;
  Timer? get refetchTimer => _refetchTimer;

  Observer({
    required this.client,
    required this.options,
  }) {
    client.queryCache.addListener(hashCode, onQueryCacheNotification);
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
    client.queryCache.removeListener(hashCode);
    client.queryCache.dismantle(this);
    resolver.cancel();
    _refetchTimer?.cancel();
  }

  /// Schedules the next fetch if the [options.refetchInterval] is set.
  void scheduleRefetch() {
    if (options.refetchInterval == null) return;
    _refetchTimer?.cancel();
    _refetchTimer = Timer(options.refetchInterval as Duration, fetch);
  }
}

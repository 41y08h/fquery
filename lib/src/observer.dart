import 'package:flutter/foundation.dart';
import 'package:fquery/src/hooks/use_query.dart';
import 'dart:async';
import 'query.dart';
import 'retry_resolver.dart';
import 'query_client.dart';

/// An observer is a class which subscribes to a query and updates its state when the query changes.
/// It is responsible for fetching the query and updating the cache.
/// There can be multiple observers for the same query and hence
/// sharing the same piece of data throughout the whole application.
class Observer<TData, TError> extends ChangeNotifier {
  final QueryKey queryKey;
  final QueryClient client;
  final Future<TData> Function() fetcher;
  late final Query<TData, TError> query;

  late QueryOptions options;
  final resolver = RetryResolver();
  Timer? refetchTimer;

  Observer(
    this.queryKey,
    this.fetcher, {
    required this.client,
    required UseQueryOptions options,
  }) {
    query = client.queryCache.build<TData, TError>(
      queryKey: queryKey,
      client: client,
    );
    _setOptions(options);
    query.setCacheDuration(this.options.cacheDuration);
  }

  // This is called from the [useQuery] hook
  // whenever the first widget build is done
  void initialize() {
    // Subcribe the any query state changes
    query.subscribe(this);

    // Initiate query on mount
    if (options.enabled == false) return;
    final isRefetching = !query.state.isLoading;
    final isInvalidated = query.state.isInvalidated;

    // [RefetchOnMount] behavior is specified here
    if (isRefetching && !isInvalidated) {
      switch (options.refetchOnMount) {
        case RefetchOnMount.always:
          fetch();
          break;
        case RefetchOnMount.stale:
          DateTime? staleAt =
              query.state.dataUpdatedAt?.add(options.staleDuration);
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

  /// Takes a [UseQueryOptions] and sets the [options] field.
  /// The [DefaultQueryOptions] from the [QueryClient]
  /// is used if a field is not specified.
  void _setOptions(UseQueryOptions options) {
    this.options = QueryOptions(
      enabled: options.enabled,
      refetchOnMount:
          options.refetchOnMount ?? client.defaultQueryOptions.refetchOnMount,
      staleDuration:
          options.staleDuration ?? client.defaultQueryOptions.staleDuration,
      cacheDuration:
          options.cacheDuration ?? client.defaultQueryOptions.cacheDuration,
      refetchInterval: options.refetchInterval,
    );
  }

  /// This is usually called from the [useQuery] hook
  /// whenever there is any change in the options
  void updateOptions(UseQueryOptions options) {
    final refetchIntervalChanged =
        this.options.refetchInterval != options.refetchInterval;

    _setOptions(options);

    if (options.cacheDuration != null) {
      query.setCacheDuration(options.cacheDuration as Duration);
    }

    if (refetchIntervalChanged) {
      // Schedules the next fetch if the [options.refetchInterval] is set.
      if (options.refetchInterval != null) {
        scheduleRefetch();
      } else {
        refetchTimer?.cancel();
        refetchTimer = null;
      }
    }
  }

  /// This is "the" function responsible for fetching the query.
  void fetch() async {
    if (!options.enabled || query.state.isFetching) {
      return;
    }

    query.dispatch(DispatchAction.fetch, null);
    resolver.resolve(fetcher, onResolve: (data) {
      query.dispatch(DispatchAction.success, data);
      scheduleRefetch();
    }, onError: (error) {
      query.dispatch(DispatchAction.error, error);
      scheduleRefetch();
    }, onCancel: () {
      query.dispatch(DispatchAction.cancelFetch, null);
    });
  }

  /// This is called from the [Query] class whenever the query state changes.
  /// It notifies the observers about the change and it also nofities the [useQuery] hook.
  void onQueryUpdated() {
    notifyListeners();
    if (query.state.isInvalidated) {
      fetch();
    }
  }

  /// This is called from the [useQuery] hook when the widget is unmounted.
  void destroy() {
    query.unsubscribe(this);
    resolver.cancel();
    refetchTimer?.cancel();
  }

  /// Schedules the next fetch if the [options.refetchInterval] is set.
  void scheduleRefetch() {
    if (options.refetchInterval == null) return;
    refetchTimer?.cancel();
    refetchTimer = Timer(options.refetchInterval as Duration, fetch);
  }
}

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'query.dart';
import 'retryer.dart';
import 'query_client.dart';

class Observer<TData, TError> extends ChangeNotifier {
  final QueryKey queryKey;
  final Future<TData> Function() fetcher;
  late final Query<TData, TError> query;

  // Options
  late QueryOptions options;
  final resolver = RetryResolver();
  Timer? refetchTimer;

  Observer(
    this.queryKey,
    this.fetcher, {
    required QueryClient client,
    QueryOptions? options,
  }) {
    query = client.buildQuery<TData, TError>(queryKey);

    this.options = options ?? client.defaultQueryOptions;
    if (options?.cacheDuration != null) {
      query.setCacheDuration(options!.cacheDuration);
    }
  }

  // This is called from the [useQuery] hook
  // whenever the first widget build is done
  void initialize() {
    // Subcribe the any query state changes
    query.subscribe(this);

    // Initiate query on mount
    if (options.enabled == false) return;
    final isRefetching = !query.state.isLoading;

    if (isRefetching) {
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

  void setOptions(QueryOptions options) {
    final refetchIntervalChanged =
        this.options.refetchInterval != options.refetchInterval;
    if (refetchIntervalChanged) {
      if (options.refetchInterval != null) {
        scheduleRefetch();
      } else {
        refetchTimer?.cancel();
        refetchTimer = null;
      }
    }

    this.options = options;
    query.setCacheDuration(options.cacheDuration);
  }

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

  void onQueryUpdated() {
    notifyListeners();
  }

  void destroy() {
    query.unsubscribe(this);
    resolver.cancel();
    refetchTimer?.cancel();
  }

  void scheduleRefetch() {
    if (options.refetchInterval == null) return;
    refetchTimer?.cancel();
    refetchTimer = Timer(options.refetchInterval as Duration, fetch);
  }
}

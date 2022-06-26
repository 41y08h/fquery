import 'package:flutter/foundation.dart';
import 'types.dart';
import 'dart:async';
import 'query.dart';
import 'retryer.dart';
import 'query_client.dart';

class Observer<TData, TError> extends ChangeNotifier {
  final String queryKey;
  final Future<TData> Function() fetcher;
  late final Query<TData, TError> query;

  // Options
  late QueryOptions options;
  final resolver = RetryResolver();

  Observer(
    this.queryKey,
    this.fetcher, {
    required QueryClient client,
    QueryOptions? options,
  }) {
    query = client.buildQuery<TData, TError>(queryKey);
    query.subscribe(this);
    if (options?.cacheDuration != null) {
      print('set cache duration');
      query.setCacheDuration(options!.cacheDuration);
    }

    onOptionsChanged(options ?? client.defaultQueryOptions);
  }

  void onOptionsChanged(QueryOptions options) {
    this.options = options;

    // Initiate query
    if (this.options.enabled == false) return;
    final isRefetching = !query.state.isLoading;

    if (isRefetching) {
      switch (this.options.refetchOnMount) {
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

  void fetch() async {
    if (!options.enabled || query.state.isFetching) {
      return;
    }

    query.dispatch(DispatchAction.fetch, null);
    resolver.resolve(fetcher, onResolve: (data) {
      query.dispatch(DispatchAction.success, data);
    }, onError: (error) {
      query.dispatch(DispatchAction.error, error);
    }, onCancel: () {
      query.dispatch(DispatchAction.cancelFetch, null);
    });
  }

  void onQueryUpdated() {
    notifyListeners();
  }

  void cleanup() {
    query.unsubscribe(this);
    resolver.cancel();
  }
}

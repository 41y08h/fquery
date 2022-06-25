import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:fquery/fquery/fquery.dart';
import 'package:fquery/fquery/query.dart';
import 'package:fquery/fquery/retryer.dart';

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
    this.options = options ?? client.defaultQueryOptions;
    query.addListener(() {
      // Propagate the change to the observer's listeners
      notifyListeners();
    });
    if (this.options.enabled) {
      fetch();
    }
  }

  void onOptionsChanged(QueryOptions options) {
    this.options = options;
    if (this.options.enabled) fetch();
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

  void cleanup() {
    resolver.cancel();
  }
}

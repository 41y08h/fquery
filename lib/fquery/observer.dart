import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:fquery/fquery/fquery.dart';
import 'package:fquery/fquery/query.dart';

class Observer<TData, TError> extends ChangeNotifier {
  final String queryKey;
  final Future<TData> Function() fetcher;
  late final Query<TData, TError> query;

  // Options
  late QueryOptions options;

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
    try {
      final data = await options.retry.retry(fetcher);
      query.dispatch(DispatchAction.success, data);
    } catch (e) {
      query.dispatch(DispatchAction.error, e);
    }
  }
}

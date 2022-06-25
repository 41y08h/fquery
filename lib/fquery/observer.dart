import 'package:flutter/cupertino.dart';
import 'package:fquery/fquery/fquery.dart';
import 'package:fquery/fquery/query.dart';

class Observer<TData, TError> extends ChangeNotifier {
  final String queryKey;
  Future<TData> Function() fetcher;
  late Query<TData, TError> query;

  bool enabled;
  Duration? refreshInterval;
  RefetchOnMount? refetchOnMount;
  double retry;
  Duration retryDelay;

  Observer(
    this.queryKey,
    this.fetcher, {
    required QueryClient client,
    this.enabled = true,
    this.refreshInterval,
    this.refetchOnMount = RefetchOnMount.stale,
    this.retry = 3,
    this.retryDelay = const Duration(milliseconds: 100),
  }) {
    query = client.buildQuery<TData, TError>(queryKey);
    query.addListener(() {
      // Propagate the change to the observer's listeners
      notifyListeners();
    });
    if (enabled) {
      fetch();
    }
  }

  void onOptionsChanged({
    bool enabled = true,
    Duration? refreshInterval,
    RefetchOnMount refetchOnMount = RefetchOnMount.stale,
    double retry = 3,
    Duration retryDelay = const Duration(milliseconds: 100),
  }) {
    this.enabled = enabled;
    this.refreshInterval = refreshInterval;
    this.refetchOnMount = refetchOnMount;
    this.retry = retry;
    this.retryDelay = retryDelay;

    if (this.enabled) fetch();
  }

  void fetch() async {
    if (!enabled || query.state.isFetching) {
      return;
    }

    query.dispatch(DispatchAction.fetch, null);
    try {
      final data = await fetcher();
      query.dispatch(DispatchAction.success, data);
    } catch (e) {
      query.dispatch(DispatchAction.error, e);
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:fquery/fquery/fquery.dart';
import 'package:fquery/fquery/query.dart';

class QueryObserver extends ChangeNotifier {
  late final Query query;

  QueryObserver(
    String queryKey, {
    required QueryClient client,
    QueryFn? queryFn,
    Duration staleDuration = Duration.zero,
    Duration? refetchInterval,
    RefetchOnReconnect refetchOnReconnect = RefetchOnReconnect.ifStale,
    dynamic Function(dynamic data)? select,
    dynamic Function(dynamic data)? transform,
    bool enabled = true,
  }) {
    query = client.buildQuery(
      queryKey,
      queryFn: queryFn,
      staleDuration: staleDuration,
      refetchInterval: refetchInterval,
      refetchOnReconnect: refetchOnReconnect,
      select: select,
      transform: transform,
      enabled: enabled,
    );
    query.addObserver(this);
    if (enabled) query.fetchData();
  }

  // Observer is removed from the query when it is disposed
  // inside a hook, we are using `useListenable` which does it for us
  @override
  void dispose() {
    query.removeObserver(this);
    super.dispose();
  }

  // Called inside [Query] class whenever we want to update the state
  // of the observer, this will cause a rebuild to happen
  void onQueryUpdated() {
    notifyListeners();
  }
}

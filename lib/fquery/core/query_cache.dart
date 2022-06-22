import 'package:fquery/fquery/core/notify_manager.dart';
import 'package:fquery/fquery/core/query.dart';
import 'package:fquery/fquery/core/query_client.dart';
import 'package:fquery/fquery/core/subscribable.dart';
import 'package:fquery/fquery/core/types.dart';

enum NotifyEvent {
  queryAdded,
  queryRemoved,
  queryUpdated,
  queryObserverAdded,
  queryObserverRemoved,
  queryObserverResultsUpdated,
}

class QueryCacheNotifyEvent<TData extends dynamic> {
  final NotifyEvent event;
  final TData data;
  QueryCacheNotifyEvent({required this.event, required this.data});
}

typedef QueryCacheListener = void Function(QueryCacheNotifyEvent event);

class QueryCache extends Subscribable {
  Map<QueryKey, Query> queriesMap = {};
  List<Query> queries = [];

  Query<TQueryFnData, TError, TData, TQueryKey>?
      get<TQueryFnData, TData, TError, TQueryKey extends QueryKey>(
          TQueryKey queryKey) {
    return queriesMap[queryKey]
        as Query<TQueryFnData, TError, TData, TQueryKey>;
  }

  void add(Query query) {
    if (queriesMap.containsKey(query.queryKey)) {
      return;
    }

    queriesMap[query.queryKey] = query;
    queries.add(query);
    notify(QueryCacheNotifyEvent(event: NotifyEvent.queryAdded, data: query));
  }

  notify(QueryCacheNotifyEvent event) {
    NotifyManager().batch(
      () => listeners.forEach(
        (listener) => {listener(event)},
      ),
    );
  }

  void remove(Query query) {
    final queryInMap = queriesMap[query.queryKey];

    if (queryInMap != null) {
      query.destroy();

      queries = queries.where((q) => q != query).toList();

      if (queryInMap == query) {
        queriesMap.remove(query.queryKey);
      }

      notify(
        QueryCacheNotifyEvent(
          event: NotifyEvent.queryRemoved,
          data: query,
        ),
      );
    }
  }

  void onOnline() {
    NotifyManager().batch(
      () => {
        for (var query in queries) {query.onOnline()}
      },
    );
  }
}

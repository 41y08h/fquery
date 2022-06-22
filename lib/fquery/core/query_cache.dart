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

class QueryCache extends Subscribable<QueryCacheListener> {
  Map<QueryKey, Query> queriesMap = {};
  List<Query> queries = [];

  Query<TData, TError, TQueryKey>? get<TData, TError, TQueryKey>(
      TQueryKey queryKey) {
    return queriesMap[queryKey];
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
    notifyManager.batch(
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

    queriesMap.remove(query.queryKey);
    queries.remove(query);
    notify(QueryCacheNotifyEvent(event: NotifyEvent.queryRemoved, data: query));
  }
}

import 'package:collection/collection.dart';

import 'package:fquery_core/src/observer.dart';
import 'package:fquery_core/src/query.dart';
import 'package:fquery_core/src/query_cache.dart';

List<T> _difference<T>(List<T> array1, List<T> array2) {
  return array1.where((x) => !array2.contains(x)).toList();
}

/// An observer for multiple queries in parallel, uses [QueryObserver] internally
/// It's different from other observer in two aspects -
///  - It doesn't inherit from [Observer],
///  - Tt doesn't subscribe to query cache.
/// It is nevertheless an [Observable]

class QueriesObserver<TData, TError extends Exception> with Observable {
  List<QueryObserver<TData, TError>> observers = [];
  final QueryCache cache;

  QueriesObserver({required this.cache});

  void dispose() {
    disposeSubscribers();
    for (var observer in observers) {
      observer.dispose();
    }
  }

  void setOptions(List<QueryOptions<TData, TError>> options) {
    final previousObservers = observers;

    // Take the queries list and find/build the observer that is associated with the query
    final newObservers = options.map((option) {
      final observer = previousObservers.firstWhereOrNull(
            (observer) => observer.queryKey == option.queryKey,
          ) ??
          QueryObserver(
            cache: cache,
            queryKey: option.queryKey,
            queryFn: option.queryFn,
            enabled: option.enabled,
            refetchOnMount: option.refetchOnMount,
            staleDuration: option.staleDuration,
            cacheDuration: option.cacheDuration,
            retryCount: option.retryCount,
            retryDelay: option.retryDelay,
            refetchInterval: option.refetchInterval,
          );

      observer.updateOptions(
        QueryOptions(
          queryKey: option.queryKey,
          queryFn: option.queryFn,
          enabled: option.enabled,
          refetchOnMount: option.refetchOnMount,
          staleDuration: option.staleDuration,
          cacheDuration: option.cacheDuration,
          retryCount: option.retryCount,
          retryDelay: option.retryDelay,
          refetchInterval: option.refetchInterval,
        ),
      );

      return observer;
    }).toList();

    _difference(newObservers, previousObservers).forEach((observer) {
      observer.subscribe(hashCode, () {
        notifyObservers();
      });
      observer.initialize();
    });

    _difference(previousObservers, newObservers).forEach((observer) {
      observer.dispose();
    });

    observers = newObservers;
    notifyObservers();
  }
}

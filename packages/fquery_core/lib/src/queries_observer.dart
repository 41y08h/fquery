import 'package:collection/collection.dart';

import 'package:fquery_core/src/observer.dart';
import 'package:fquery_core/src/query.dart';
import 'package:fquery_core/src/query_cache.dart';

List<T> _difference<T>(List<T> array1, List<T> array2) {
  return array1.where((x) => !array2.contains(x)).toList();
}

/// Observes multiple queries in parallel.
///
/// This class owns one [QueryObserver] for each configured query option and
/// forwards child observer notifications to its own subscribers. Unlike the
/// single-query observers, it does not extend [Observer] and does not subscribe
/// directly to the query cache.
class QueriesObserver<TData, TError extends Exception> with Observable {
  /// The active child observers, in the same order as the latest options list.
  List<QueryObserver<TData, TError>> observers = [];
  bool isReadOnly;

  /// The cache used by all child query observers.
  final QueryCache cache;

  /// Creates a [QueriesObserver] backed by [cache].
  QueriesObserver({this.isReadOnly = false, required this.cache});

  /// Disposes all child observers and removes subscribers.
  void dispose() {
    disposeSubscribers();
    for (var observer in observers) {
      observer.dispose();
    }
  }

  /// Reconciles child observers with [options].
  ///
  /// Existing observers with matching query keys are reused and updated. New
  /// observers are created and initialized, while removed observers are disposed.
  void setOptions(List<QueryOptions<TData, TError>> options) {
    final previousObservers = observers;

    // Take the queries list and find/build the observer that is associated with the query
    final newObservers = options.map((option) {
      final observer = previousObservers.firstWhereOrNull(
            (observer) => observer.queryKey == option.queryKey,
          ) ??
          QueryObserver(
            isReadOnly: isReadOnly,
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

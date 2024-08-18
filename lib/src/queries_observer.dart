// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';

import 'package:fquery/fquery.dart';
import 'package:fquery/src/observer.dart';

typedef QueriesOptions<TData, TError> = UseQueriesOptions<TData, TError>;

List<T> difference<T>(List<T> array1, List<T> array2) {
  return array1.where((x) => !array2.contains(x)).toList();
}

typedef QueriesObserverOptions<TData, TError>
    = List<QueriesOptions<TData, TError>>;

class QueriesObserver<TData, TError> extends ChangeNotifier {
  final QueryClient client;
  List<Observer<TData, TError>> observers = [];

  QueriesObserver({
    required this.client,
  });

  void destroy() {
    for (var observer in observers) {
      observer.destroy();
    }
  }

  void setOptions(QueriesObserverOptions<TData, TError> options) {
    final previousObservers = observers;

    // Take the queries list and find/build the observer that is associated with the query
    final newObservers = options.map(
      (option) {
        final observer = previousObservers.firstWhereOrNull(
              (observer) => observer.queryKey.lock == option.queryKey.lock,
            ) ??
            Observer<TData, TError>(
              option.queryKey,
              option.fetcher,
              client: client,
              options: UseQueryOptions(
                enabled: option.enabled,
                cacheDuration: option.cacheDuration,
                refetchInterval: option.refetchInterval,
                refetchOnMount: option.refetchOnMount,
                staleDuration: option.staleDuration,
                retryCount: option.retryCount,
                retryDelay: option.retryDelay,
              ),
            );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          observer.updateOptions(UseQueryOptions(
            enabled: option.enabled,
            cacheDuration: option.cacheDuration,
            refetchInterval: option.refetchInterval,
            refetchOnMount: option.refetchOnMount,
            staleDuration: option.staleDuration,
            retryCount: option.retryCount,
            retryDelay: option.retryDelay,
          ));
        });
        return observer;
      },
    ).toList();

    difference(newObservers, previousObservers).forEach((observer) {
      observer.addListener(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        observer.initialize();
      });
    });

    difference(previousObservers, newObservers).forEach((observer) {
      observer.destroy();
    });

    observers = newObservers;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}

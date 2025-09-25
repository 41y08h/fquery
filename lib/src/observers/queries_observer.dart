// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import 'package:fquery/fquery.dart';
import 'package:fquery/src/data_classes/query_options.dart';
import 'package:fquery/src/observers/observer.dart';

typedef QueriesOptions<TData, TError extends Exception>
    = QueryOptions<TData, TError>;

List<T> difference<T>(List<T> array1, List<T> array2) {
  return array1.where((x) => !array2.contains(x)).toList();
}

typedef QueriesObserverOptions<TData, TError extends Exception>
    = List<QueriesOptions<TData, TError>>;

class QueriesObserver<TData, TError extends Exception> extends ChangeNotifier {
  final QueryClient client;
  List<Observer<TData, TError>> observers = [];

  QueriesObserver({
    required this.client,
  });

  @override
  void dispose() {
    for (var observer in observers) {
      observer.dispose();
    }
    super.dispose();
  }

  void setOptions(QueriesObserverOptions<TData, TError> options) {
    final previousObservers = observers;

    // Take the queries list and find/build the observer that is associated with the query
    final newObservers = options.map(
      (option) {
        final observer = previousObservers.firstWhereOrNull(
              (observer) => observer.options.queryKey == option.queryKey,
            ) ??
            Observer(
              client: client,
              options: QueryOptions(
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
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
        });
        return observer;
      },
    ).toList();

    difference(newObservers, previousObservers).forEach((observer) {
      observer.addListener(() {
        notifyListeners();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        observer.initialize();
      });
    });

    difference(previousObservers, newObservers).forEach((observer) {
      observer.dispose();
    });

    observers = newObservers;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}

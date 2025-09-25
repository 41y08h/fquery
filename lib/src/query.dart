// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/observers/observer.dart';
import 'package:fquery/src/data_classes/query_key.dart';
import 'package:fquery/src/data_classes/query_state.dart';
import 'package:fquery/src/removable.dart';

enum DispatchAction {
  fetch,
  error,
  success,
  cancelFetch,
  invalidate,
  refetchSequence,
  refetchError,
}

enum QueryStatus {
  loading,
  success,
  error,
}

enum RefetchOnMount {
  stale,
  always,
  never,
}

class BaseQueryOptions<TData, TError> {
  final QueryKey queryKey;
  final bool enabled;
  final RefetchOnMount refetchOnMount;
  final Duration staleDuration;
  final Duration cacheDuration;
  final Duration? refetchInterval;
  final int retryCount;
  final Duration retryDelay;

  BaseQueryOptions({
    required this.queryKey,
    this.enabled = true,
    this.refetchOnMount = RefetchOnMount.stale,
    this.staleDuration = Duration.zero,
    this.cacheDuration = const Duration(minutes: 5),
    this.refetchInterval,
    this.retryCount = 3,
    this.retryDelay = const Duration(seconds: 1, milliseconds: 500),
  });
}

enum FetchDirection { forward, backward }

class FetchMeta {
  FetchDirection direction;
  FetchMeta({
    required this.direction,
  });

  FetchMeta copyWith({
    FetchDirection? direction,
  }) {
    return FetchMeta(
      direction: direction ?? this.direction,
    );
  }
}

class Query<TData, TError extends Exception> extends ChangeNotifier
    with Removable {
  final QueryClient client;
  final QueryKey key;

  QueryState<TData, TError> _state = QueryState<TData, TError>();
  QueryState<TData, TError> get state => _state;

  Query({required this.client, required this.key});

  /// The single source of truth for how the cache data changes.
  QueryState<TData, TError> _reducer(
      QueryState<TData, TError> state, DispatchAction action, dynamic data) {
    switch (action) {
      case DispatchAction.fetch:
        return state.copyWith(
          isFetching: true,
          status:
              state.dataUpdatedAt == null ? QueryStatus.loading : state.status,
          fetchMeta: data,
        );
      case DispatchAction.cancelFetch:
        return state.copyWith(
          isFetching: false,
          fetchMeta: null,
        );
      case DispatchAction.error:
        return state.copyWith(
          status: QueryStatus.error,
          error: data as TError,
          errorUpdatedAt: DateTime.now(),
          isFetching: false,
          isInvalidated: false,
          fetchMeta: state.fetchMeta,
        );
      case DispatchAction.success:
        return state.copyWith(
          status: QueryStatus.success,
          error: null,
          data: data as TData,
          dataUpdatedAt: DateTime.now(),
          isFetching: false,
          isInvalidated: false,
          fetchMeta: null,
        );
      case DispatchAction.invalidate:
        return state.copyWith(
          isInvalidated: true,
        );
      case DispatchAction.refetchSequence:
        return state.copyWith(
          error: null,
          data: data as TData,
          dataUpdatedAt: DateTime.now(),
          isInvalidated: false,
          fetchMeta: null,
        );
      case DispatchAction.refetchError:
        return state.copyWith(
          isRefetchError: true,
          status: QueryStatus.error,
          error: data as TError,
          errorUpdatedAt: DateTime.now(),
          isFetching: false,
          isInvalidated: false,
          fetchMeta: null,
        );
      default:
        return state;
    }
  }

  /// Dispatches an action to the reducer and notifies observers
  void dispatch(DispatchAction action, dynamic data) {
    _state = _reducer(state, action, data);
    notifyListeners();
    client.queryCache.onQueryUpdated();
  }

  /// This is called from the [Observer]
  /// to subscribe to the query
  void subscribe() {
    // _listeners.add(observer);

    // At least we have one observer
    // So no need to garbage collect
    cancelGarbageCollection();
  }

  void unsubscribe() {
    // _listeners.remove(observer);

    // if (_listeners.isEmpty) {
    //   scheduleGarbageCollection();
    // }
  }

  /// This is called when garbage collection timer fires
  @override
  void onGarbageCollection() {
    super.onGarbageCollection();
    client.queryCache.remove(this);
  }
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:fquery/fquery.dart';
import 'package:fquery/src/observer.dart';
import 'package:fquery/src/query_listener.dart';
import 'package:fquery/src/removable.dart';

typedef QueryKey = List<dynamic>;

enum DispatchAction {
  fetch,
  error,
  success,
  cancelFetch,
  invalidate,
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

class QueryOptions<TData, TError> {
  final bool enabled;
  final RefetchOnMount refetchOnMount;
  final Duration staleDuration;
  final Duration cacheDuration;
  final Duration? refetchInterval;
  final int retryCount;
  final Duration retryDelay;

  QueryOptions({
    required this.enabled,
    required this.refetchOnMount,
    required this.staleDuration,
    required this.cacheDuration,
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

class QueryState<TData, TError> {
  final TData? data;
  final TError? error;
  final DateTime? dataUpdatedAt;
  final DateTime? errorUpdatedAt;
  final bool isFetching;
  final QueryStatus status;
  final bool isInvalidated;
  final FetchMeta? fetchMeta;

  bool get isLoading => status == QueryStatus.loading;
  bool get isSuccess => status == QueryStatus.success;
  bool get isError => status == QueryStatus.error;

  QueryState({
    this.data,
    this.error,
    this.dataUpdatedAt,
    this.errorUpdatedAt,
    this.isFetching = false,
    this.status = QueryStatus.loading,
    this.isInvalidated = false,
    this.fetchMeta,
  });

  QueryState<TData, TError> copyWith({
    TData? data,
    TError? error,
    DateTime? dataUpdatedAt,
    DateTime? errorUpdatedAt,
    bool? isFetching,
    QueryStatus? status,
    bool? isInvalidated,
    FetchMeta? fetchMeta,
  }) {
    return QueryState<TData, TError>(
      data: data ?? this.data,
      error: error ?? this.error,
      dataUpdatedAt: dataUpdatedAt ?? this.dataUpdatedAt,
      errorUpdatedAt: errorUpdatedAt ?? this.errorUpdatedAt,
      isFetching: isFetching ?? this.isFetching,
      status: status ?? this.status,
      isInvalidated: isInvalidated ?? this.isInvalidated,
      fetchMeta: fetchMeta ?? this.fetchMeta,
    );
  }
}

class Query<TData, TError> with Removable {
  final QueryClient client;
  final QueryKey key;

  QueryState<TData, TError> _state = QueryState<TData, TError>();
  QueryState<TData, TError> get state => _state;
  final List<QueryListener> _listeners = [];

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
        );
      case DispatchAction.error:
        return state.copyWith(
          status: QueryStatus.error,
          data: null,
          error: data as TError,
          errorUpdatedAt: DateTime.now(),
          isFetching: false,
          isInvalidated: false,
        );
      case DispatchAction.success:
        return state.copyWith(
          status: QueryStatus.success,
          error: null,
          data: data as TData,
          dataUpdatedAt: DateTime.now(),
          isFetching: false,
          isInvalidated: false,
        );
      case DispatchAction.invalidate:
        return state.copyWith(
          isInvalidated: true,
        );
      default:
        return state;
    }
  }

  /// Dispatches an action to the reducer and notifies observers
  void dispatch(DispatchAction action, dynamic data) {
    _state = _reducer(state, action, data);
    _notifyListeners();
    client.queryCache.onQueryUpdated();

    // Refetching is scheduled here after success or error
    final scheduleRefetchActions = [
      DispatchAction.success,
      DispatchAction.error
    ];
    if (scheduleRefetchActions.contains(action)) {
      for (var listener in _listeners) {
        listener.scheduleRefetch();
      }
    }
  }

  /// This is called from the [Observer]
  /// to subscribe to the query
  void subscribe(QueryListener observer) {
    _listeners.add(observer);

    // At least we have one observer
    // So no need to garbage collect
    cancelGarbageCollection();
  }

  void unsubscribe(QueryListener observer) {
    _listeners.remove(observer);

    if (_listeners.isEmpty) {
      scheduleGarbageCollection();
    }
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener.onQueryUpdated();
    }
  }

  /// This is called when garbage collection timer fires
  @override
  void onGarbageCollection() {
    super.onGarbageCollection();
    client.queryCache.remove(this);
  }
}

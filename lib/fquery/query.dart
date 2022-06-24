import 'package:fquery/fquery/fquery.dart';
import 'package:fquery/fquery/query_observer.dart';

enum DispatchAction {
  fetch,
  error,
  success,
  invalidate,
  setState,
}

class Query {
  final String queryKey;
  final QueryClient client;
  List<QueryObserver> observers = [];

  QueryState state;
  QueryFn? queryFn;
  dynamic Function(dynamic data)? transform;

  Query({
    required this.client,
    required this.queryKey,
    required this.state,
    this.queryFn,
    this.transform,
  }) {
    queryFn = queryFn ?? client.defaultOptions?.queryFn;
    if (queryFn == null) {
      throw Exception('QueryFn is missing, please provide one');
    }
  }

  Future<void> fetchData() async {
    dispatch(DispatchAction.fetch, null);
    try {
      final data = await queryFn?.call(queryKey);
      setData((previous) {
        return transform == null ? data : transform?.call(data);
      });
    } catch (e) {
      dispatch(DispatchAction.error, e);
    }
  }

  void invalidate() {
    dispatch(DispatchAction.invalidate, null);
    fetchData();
  }

  void setData<TData>(TData Function(TData previous) updater) {
    dispatch(DispatchAction.success, updater(state.data));
  }

  QueryState reducer(QueryState state, DispatchAction action, dynamic data) {
    switch (action) {
      case DispatchAction.fetch:
        return state.copyWith(
          status: state.data == null ? QueryStatus.loading : QueryStatus.idle,
          isFetching: true,
        );
      case DispatchAction.error:
        return state.copyWith(
          error: data,
          errorUpdatedAt: DateTime.now(),
        );
      case DispatchAction.success:
        return state.copyWith(
          status: QueryStatus.success,
          isFetching: false,
          error: null,
          data: data,
          dataUpdatedAt: DateTime.now(),
        );
      case DispatchAction.invalidate:
        return state.copyWith(
          isStale: true,
        );
      case DispatchAction.setState:
        return data;
      default:
        return state;
    }
  }

  void dispatch(DispatchAction action, dynamic data) {
    state = reducer(state, action, data);
    for (var observer in observers) {
      observer.onQueryUpdated();
    }
  }

  void addObserver(QueryObserver observer) {
    if (observers.contains(observer)) return;
    observers.add(observer);
  }

  void removeObserver(QueryObserver observer) {
    observers.remove(observer);
  }
}

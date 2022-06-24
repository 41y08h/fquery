import 'package:flutter/foundation.dart';
import 'package:fquery/fquery/types.dart';

enum DispatchAction {
  fetch,
  error,
  success,
  invalidate,
  setState,
}

class Query extends ChangeNotifier {
  final String queryKey;
  QueryState state;
  QueryFn<dynamic> queryFn;
  dynamic Function(dynamic data)? transform;

  Query({
    required this.queryKey,
    required this.state,
    required this.queryFn,
    this.transform,
  });

  Future<void> fetchData() async {
    print("fetching");
    dispatch(DispatchAction.fetch, null);
    try {
      final data = await queryFn();
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
          isLoading: state.data != null ? false : true,
          isFetching: true,
        );
      case DispatchAction.error:
        return state.copyWith(
          error: data,
          errorUpdatedAt: DateTime.now(),
        );
      case DispatchAction.success:
        return state.copyWith(
          isLoading: false,
          isFetching: false,
          isError: false,
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
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:fquery/fquery/fquery.dart';

enum DispatchAction {
  fetch,
  error,
  success,
}

class Query<TData, TError> extends ChangeNotifier {
  QueryState<TData, TError> _state = QueryState();
  QueryState<TData, TError> get state => _state;

  QueryState<TData, TError> _reducer(
      QueryState<TData, TError> state, DispatchAction action, dynamic data) {
    switch (action) {
      case DispatchAction.fetch:
        return state.copyWith(
          isFetching: true,
        );
      case DispatchAction.error:
        return state.copyWith(
          status: QueryStatus.error,
          error: data,
          errorUpdatedAt: DateTime.now(),
          isFetching: false,
        );
      case DispatchAction.success:
        return state.copyWith(
          status: QueryStatus.success,
          error: null,
          data: data,
          dataUpdatedAt: DateTime.now(),
          isFetching: false,
        );
      default:
        return state;
    }
  }

  void dispatch(DispatchAction action, dynamic data) {
    _state = _reducer(state, action, data);
    notifyListeners();
  }
}

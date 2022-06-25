import 'package:flutter/foundation.dart';
import 'package:fquery/fquery/fquery.dart';

enum DispatchAction {
  error,
  success,
}

class Query<TData, TError> extends ChangeNotifier {
  QueryState<TData, TError> _state = QueryState();
  QueryState<TData, TError> get state => _state;

  void setIsFetching(bool value) {
    _state = _state.copyWith(isFetching: value);
    notifyListeners();
  }

  void setData(TData data) {
    dispatch(DispatchAction.success, data);
  }

  void setError(TError error) {
    dispatch(DispatchAction.error, error);
  }

  QueryState<TData, TError> _reducer(
      QueryState<TData, TError> state, DispatchAction action, dynamic data) {
    switch (action) {
      case DispatchAction.error:
        return state.copyWith(
          error: data,
          errorUpdatedAt: DateTime.now(),
        );
      case DispatchAction.success:
        return state.copyWith(
          error: null,
          data: data,
          dataUpdatedAt: DateTime.now(),
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

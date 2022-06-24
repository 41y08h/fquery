import 'package:flutter/widgets.dart';
import 'package:fquery/fquery/types.dart';

class QueryResult extends QueryState {
  QueryResult(QueryState state)
      : super(
          data: state.data,
          error: state.error,
          isLoading: state.isLoading,
          isFetching: state.isFetching,
          isStale: state.isStale,
          dataUpdatedAt: state.dataUpdatedAt,
          errorUpdatedAt: state.errorUpdatedAt,
        );

  Widget when<TData, TError>(
      {required Widget Function() loading,
      required Widget Function(TError error) error,
      required Widget Function(TData data) data}) {
    if (isLoading) {
      return loading();
    } else if (this.error != null) {
      return error(this.error);
    }
    return data(this.data);
  }
}

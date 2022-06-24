import 'package:flutter/widgets.dart';
import 'package:fquery/fquery/types.dart';

class QueryResult {
  late final dynamic data;
  late final dynamic error;
  late final bool isLoading;
  late final bool isFetching;
  late final bool isStale;
  late final DateTime? dataUpdatedAt;
  late final DateTime? errorUpdatedAt;

  QueryResult(QueryState state) {
    data = state.data;
    error = state.error;
    isLoading = state.isLoading;
    isFetching = state.isFetching;
    isStale = state.isStale;
    dataUpdatedAt = state.dataUpdatedAt;
    errorUpdatedAt = state.errorUpdatedAt;
  }

  Widget when<TData, TError>(
      {required Widget Function() inLoading,
      required Widget Function(TError error) inError,
      required Widget Function(TData data) inData}) {
    if (isLoading) {
      return inLoading();
    } else if (error != null) {
      return inError(error as TError);
    }
    return inData(data as TData);
  }
}

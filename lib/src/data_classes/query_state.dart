import 'package:fquery/src/query.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'query_state.freezed.dart';

@freezed

/// State of a query.
class QueryState<TData, TError> with _$QueryState<TData, TError> {
  const QueryState._();

  /// Tells if is fetching for the first time.
  bool get isLoading => status == QueryStatus.loading;

  /// Tells if the query was successful.
  bool get isSuccess => status == QueryStatus.success;

  /// Tells if the query is in error state.
  bool get isError => status == QueryStatus.error;

  /// Creates a new instance of [QueryState].
  const factory QueryState({
    TData? data,
    TError? error,
    DateTime? dataUpdatedAt,
    DateTime? errorUpdatedAt,
    @Default(false) bool isFetching,
    @Default(QueryStatus.loading) QueryStatus status,
    @Default(false) bool isInvalidated,
    FetchMeta? fetchMeta,
    @Default(false) bool isRefetchError,
  }) = _QueryState<TData, TError>;
}

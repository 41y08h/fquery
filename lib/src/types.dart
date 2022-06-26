enum QueryStatus {
  loading,
  success,
  error,
}

class QueryState<TData, TError> {
  TData? data;
  TError? error;
  DateTime? dataUpdatedAt;
  DateTime? errorUpdatedAt;
  bool isFetching;
  QueryStatus status;

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
  });

  QueryState<TData, TError> copyWith({
    dynamic data,
    dynamic error,
    DateTime? dataUpdatedAt,
    DateTime? errorUpdatedAt,
    bool? isFetching,
    QueryStatus? status,
  }) {
    return QueryState(
      data: data ?? this.data,
      error: error ?? this.error,
      dataUpdatedAt: dataUpdatedAt ?? this.dataUpdatedAt,
      errorUpdatedAt: errorUpdatedAt ?? this.errorUpdatedAt,
      isFetching: isFetching ?? this.isFetching,
      status: status ?? this.status,
    );
  }
}

enum RefetchOnMount {
  stale,
  always,
  never,
}

class QueryOptions {
  bool enabled;
  RefetchOnMount refetchOnMount;
  Duration staleDuration;
  Duration cacheDuration;

  QueryOptions({
    this.enabled = true,
    this.refetchOnMount = RefetchOnMount.stale,
    this.staleDuration = const Duration(seconds: 0),
    this.cacheDuration = const Duration(minutes: 5),
  });
}

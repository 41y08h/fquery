enum RefetchOnReconnect {
  always,
  ifStale,
  never,
}

enum QueryStatus {
  idle,
  loading,
  error,
  success,
}

class QueryState {
  bool isFetching;
  int fetchFailureCount;

  bool get isIdle => status == QueryStatus.idle;
  bool get isError => status == QueryStatus.error;
  bool get isLoading => status == QueryStatus.loading;

  dynamic data;
  dynamic error;
  DateTime? dataUpdatedAt;
  DateTime? errorUpdatedAt;
  bool isStale;
  QueryStatus status;

  QueryState({
    this.isFetching = false,
    this.data = false,
    this.error = false,
    this.dataUpdatedAt,
    this.errorUpdatedAt,
    this.isStale = false,
    this.fetchFailureCount = 0,
    required this.status,
  });

  QueryState copyWith({
    bool? isFetching,
    dynamic data,
    dynamic error,
    DateTime? dataUpdatedAt,
    DateTime? errorUpdatedAt,
    bool? isStale,
    int? fetchFailureCount,
    QueryStatus? status,
  }) {
    return QueryState(
      isFetching: isFetching ?? this.isFetching,
      data: data ?? this.data,
      error: error ?? this.error,
      dataUpdatedAt: dataUpdatedAt ?? this.dataUpdatedAt,
      errorUpdatedAt: errorUpdatedAt ?? this.errorUpdatedAt,
      isStale: isStale ?? this.isStale,
      fetchFailureCount: fetchFailureCount ?? this.fetchFailureCount,
      status: status ?? this.status,
    );
  }
}

typedef QueryFn<T> = Future<T> Function(String queryKey);

class QueryClientDefaultOptions<TQueryFnData> {
  Future<dynamic> Function(String queryKey) queryFn;

  QueryClientDefaultOptions({
    required this.queryFn,
  });
}

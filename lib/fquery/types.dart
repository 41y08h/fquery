enum RefetchOnReconnect {
  always,
  ifStale,
  never,
}

class QueryState {
  bool isLoading;
  bool isFetching;
  int fetchFailureCount;
  bool isError;
  bool isFetched;

  dynamic data;
  dynamic error;
  DateTime? dataUpdatedAt;
  DateTime? errorUpdatedAt;
  bool isStale;

  QueryState({
    this.isLoading = true,
    this.isFetching = true,
    this.data,
    this.error,
    this.dataUpdatedAt,
    this.errorUpdatedAt,
    this.isStale = false,
    this.fetchFailureCount = 0,
    this.isError = false,
    this.isFetched = false,
  });

  QueryState copyWith({
    bool? isLoading,
    bool? isFetching,
    dynamic data,
    dynamic error,
    DateTime? dataUpdatedAt,
    DateTime? errorUpdatedAt,
    bool? isStale,
    int? fetchFailureCount,
    bool? isError,
    bool? isFetched,
  }) {
    return QueryState(
      isLoading: isLoading ?? this.isLoading,
      isFetching: isFetching ?? this.isFetching,
      data: data ?? this.data,
      error: error ?? this.error,
      dataUpdatedAt: dataUpdatedAt ?? this.dataUpdatedAt,
      errorUpdatedAt: errorUpdatedAt ?? this.errorUpdatedAt,
      isStale: isStale ?? this.isStale,
      fetchFailureCount: fetchFailureCount ?? this.fetchFailureCount,
      isError: isError ?? this.isError,
      isFetched: isFetched ?? this.isFetched,
    );
  }
}

typedef QueryFn<T> = Future<T> Function();

class QueryClientDefaultOptions<TQueryFnData> {
  Future<dynamic> Function(String queryKey) queryFn;

  QueryClientDefaultOptions({
    required this.queryFn,
  });
}

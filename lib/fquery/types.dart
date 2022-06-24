enum RefetchOnReconnect {
  always,
  ifStale,
  never,
}

class QueryState {
  bool isLoading;
  bool isFetching;
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
  });

  QueryState copyWith({
    bool? isLoading,
    bool? isFetching,
    dynamic data,
    dynamic error,
    DateTime? dataUpdatedAt,
    DateTime? errorUpdatedAt,
    bool? isStale,
  }) {
    return QueryState(
      isLoading: isLoading ?? this.isLoading,
      isFetching: isFetching ?? this.isFetching,
      data: data ?? this.data,
      error: error ?? this.error,
      dataUpdatedAt: dataUpdatedAt ?? this.dataUpdatedAt,
      errorUpdatedAt: errorUpdatedAt ?? this.errorUpdatedAt,
      isStale: isStale ?? this.isStale,
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

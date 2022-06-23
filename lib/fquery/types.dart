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

  QueryState({
    this.isLoading = true,
    this.isFetching = true,
    this.data,
    this.error,
    this.dataUpdatedAt,
    this.errorUpdatedAt,
  });
}

typedef QueryFn<T> = Future<T> Function();

class QueryClientDefaultOptions<TQueryFnData> {
  QueryFn? queryFn;

  QueryClientDefaultOptions({
    this.queryFn,
  });
}

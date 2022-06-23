import 'dart:async';

import 'package:fquery/fquery/core/query.dart';
import 'package:fquery/fquery/core/query_cache.dart';
import 'package:fquery/fquery/core/query_client.dart';
import 'package:fquery/fquery/core/subscribable.dart';
import 'package:fquery/fquery/core/types.dart';
import 'package:fquery/fquery/core/utils.dart';

class QueryObserverResult<TData extends dynamic, TError extends dynamic> {
  TData? data;
  DateTime? dataUpdatedAt;
  TError? error;
  DateTime? errorUpdatedAt;
  int failureCount;
  int errorUpdateCount;
  bool isError;
  bool isFetched;
  bool isFetchedAfterMount;
  bool isFetching;
  bool isLoading;
  bool isLoadingError;
  bool isPaused;
  bool isPlaceholderData;
  bool isPreviousData;
  bool isRefetchError;
  bool isRefetching;
  bool isStale;
  bool isSuccess;
  Future<QueryObserverResult<TData, TError>> Function(dynamic options) refetch;
  void Function() remove;
  QueryStatus status;
  FetchStatus fetchStatus;

  QueryObserverResult({
    this.data,
    this.dataUpdatedAt,
    this.error,
    this.errorUpdatedAt,
    required this.failureCount,
    required this.errorUpdateCount,
    required this.isError,
    required this.isFetched,
    required this.isFetchedAfterMount,
    required this.isFetching,
    required this.isLoading,
    required this.isLoadingError,
    required this.isPaused,
    required this.isPlaceholderData,
    required this.isPreviousData,
    required this.isRefetchError,
    required this.isRefetching,
    required this.isStale,
    required this.isSuccess,
    required this.refetch,
    required this.remove,
    required this.status,
    required this.fetchStatus,
  });
}

class QueryObserverOptions<
        TQueryFnData extends dynamic,
        TError extends dynamic,
        TData extends dynamic,
        TQueryData extends dynamic,
        TQueryKey extends QueryKey>
    extends QueryOptions<TQueryFnData, TError, TData, TQueryKey> {
  bool? enabled;
  Duration? staleDuration;
  dynamic refetchDuration;
  bool? refetchIntervalInBakground;
  dynamic refetchOnWindowFocus;
  dynamic refetchOnReconnect;
  dynamic refetchOnMount;
  bool? retryOnMount;
  dynamic notifyOnChangeProps;
  void Function(TData data)? onSuccess;
  void Function(TError error)? onError;
  void Function(TData? data, TError error)? onSetteled;
  TData Function(TQueryData data)? select;
  bool? keepPreviousData;
  TQueryData? placeholderData;
}

class NotifyOptions {
  bool? cache;
  bool? listeners;
  bool? onError;
  bool? onSuccess;

  NotifyOptions({
    this.cache,
    this.listeners,
    this.onError,
    this.onSuccess,
  });
}

typedef QueryObserverListener<TData, TError> = void Function(
    QueryObserverResult result);

class QueryObserver<
    TQueryFnData extends dynamic,
    TData extends dynamic,
    TError extends dynamic,
    TQueryData extends dynamic,
    TQueryKey extends QueryKey> extends Subscribable {
  final QueryObserverOptions<TQueryFnData, TError, TData, TQueryData, TQueryKey>
      options;

  late QueryClient _client;
  late Query<TQueryFnData, TError, TQueryData, TQueryKey> currentQuery;
  late QueryState<TData, TError> currentQueryInitialState;
  late QueryObserverResult<TData, TError> currentResult;
  QueryState<TData, TError>? currentResultState;
  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData, TQueryKey>?
      currentResultOptions;
  QueryObserverResult<TData, TError>? previousQueryResult;
  TError? selectError;
  void Function(TData data)? selectFn;
  TData? selectResult;
  Timer? staleTimer;
  Timer? refetchTimer;
  int? currentRefetchInterval;
  dynamic trackedProps;

  QueryObserver({required QueryClient client, required this.options}) {
    _client = client;
    trackedProps = <dynamic>{};
    setOptions(options);
  }

  void setOptions(
    QueryObserverOptions<TQueryFnData, TError, TData, TQueryData, TQueryKey>?
        options,
    NotifyOptions? notifyOptions,
  ) {
    final prevOptions = this.options;
    final prevQuery = currentQuery;

    // TODO: implement when query client class is ready
    // this.options = this._client

    enforceTypes([bool, Null], this.options.enabled, 'enabled');

    // Keep previous query key if the user does not supply one
    if (this.options.queryKey == null) {
      this.options.queryKey = prevOptions.queryKey;
    }

    this.updateQuery();

    final mounted = hasListeners;

    // Fetch if there are subscribers
    if (mounted &&
        shouldFetchOptionally(
            currentQuery, prevQuery, this.options, prevOptions)) {
      this.executeFetch();
    }

    updateResult(notifyOptions);

    // Update stale interval if needed
    if (mounted &&
        (currentQuery != prevQuery ||
            this.options.enabled != prevOptions.enabled ||
            this.options.staleDuration != prevOptions.staleDuration)) {
      this.updateStaleTimer();
    }

    final nextRefetchInterval = this.computeRefetchInverval();

    // Update refetch interval if needed
    if (mounted &&
        (currentQuery != prevQuery ||
            this.options.enabled != prevOptions.enabled ||
            nextRefetchInterval != currentRefetchInterval)) {
      this.updateRefetchTimer();
    }

    QueryObserverResult<TData, TError> getOptimisticResult(
      QueryObserverOptions<TQueryFnData, TError, TData, TQueryData, TQueryKey>
          options,
    ) {
      final query = _client.getQueryCache().build(_client, options);
      return createResult(query, options);
    }

    QueryObserverResult<TData, TError> getCurrentResult() {
      return currentResult;
    }

    Query<TQueryFnData, TError, TQueryData, TQueryKey> getCurrentQuery() {
      return currentQuery;
    }

    void remove() {
      _client.getQueryCache().remove(currentQuery);
    }

    void refetch<TPageData>() {}
  }

  void onQueryUpdate(DispatchAction action, dynamic data) {}
}

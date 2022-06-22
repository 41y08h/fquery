import 'dart:io';

import 'package:fquery/fquery/core/logger.dart';
import 'package:fquery/fquery/core/notify_manager.dart';
import 'package:fquery/fquery/core/online_manager.dart';
import 'package:fquery/fquery/core/query_cache.dart';
import 'package:fquery/fquery/core/query_observer.dart';
import 'package:fquery/fquery/core/removable.dart';
import 'package:fquery/fquery/core/retryer.dart';
import 'package:fquery/fquery/core/types.dart';
import 'package:fquery/fquery/core/utils.dart';

enum QueryNetworkMode {
  online,
  always,
  offlineFirst,
}

typedef QueryFunction<T extends dynamic, TQueryKey extends QueryKey> = Future<T>
    Function(QueryFunctionContext<TQueryKey, dynamic> context);
typedef QueryMeta = Map<String, dynamic>;
typedef QueryKeyHashFunction<TQueryKey extends QueryKey> = String Function(
    TQueryKey queryKey);

enum QueryStatus { loading, error, success }

enum FetchStatus { fetching, paused, idle }

class QueryState<TData extends dynamic, TError extends dynamic> {
  TData? data;
  int dataUpdateCount;
  DateTime? dataUpdatedAt;
  TError? error;
  int errorUpdateCount;
  DateTime? errorUpdatedAt;
  int fetchFailureCount;
  dynamic fetchMeta;
  bool isInvalidated;
  QueryStatus status;
  FetchStatus fetchStatus;

  QueryState({
    this.data,
    this.error,
    required this.dataUpdateCount,
    this.dataUpdatedAt,
    required this.errorUpdateCount,
    this.errorUpdatedAt,
    required this.fetchFailureCount,
    required this.fetchMeta,
    required this.isInvalidated,
    required this.status,
    required this.fetchStatus,
  });

  QueryState<TData, TError> copyWith({
    TData? data,
    TError? error,
    int? dataUpdateCount,
    DateTime? dataUpdatedAt,
    int? errorUpdateCount,
    DateTime? errorUpdatedAt,
    int? fetchFailureCount,
    dynamic fetchMeta,
    bool? isInvalidated,
    QueryStatus? status,
    FetchStatus? fetchStatus,
  }) {
    return QueryState(
      data: data ?? this.data,
      error: error ?? this.error,
      dataUpdateCount: dataUpdateCount ?? this.dataUpdateCount,
      dataUpdatedAt: dataUpdatedAt ?? this.dataUpdatedAt,
      errorUpdateCount: errorUpdateCount ?? this.errorUpdateCount,
      errorUpdatedAt: errorUpdatedAt ?? this.errorUpdatedAt,
      fetchFailureCount: fetchFailureCount ?? this.fetchFailureCount,
      fetchMeta: fetchMeta ?? this.fetchMeta,
      isInvalidated: isInvalidated ?? this.isInvalidated,
      status: status ?? this.status,
      fetchStatus: fetchStatus ?? this.fetchStatus,
    );
  }
}

class FetchOptions {
  bool? cancelRefetch;
  dynamic meta;

  FetchOptions({
    this.cancelRefetch,
    this.meta,
  });
}

class FetchContext<TQueryFnData, TError, TData, TQueryKey extends QueryKey> {
  final Future Function() fetchFn;
  final FetchOptions? fetchOptions;
  final QueryOptions<TQueryFnData, TError, TData, TQueryKey> queryOptions;
  final TQueryKey queryKey;
  final QueryState state;
  final QueryMeta? meta;

  FetchContext({
    required this.fetchFn,
    this.fetchOptions,
    required this.queryOptions,
    required this.queryKey,
    required this.state,
    this.meta,
  });
}

class QueryBehavior<TQueryFunctionData extends dynamic, TError extends dynamic,
    TData extends dynamic, TQueryKey extends QueryKey> {
  final Function(
          FetchContext<TQueryFunctionData, TError, TData, TQueryKey> context)
      onFetch;

  QueryBehavior({
    required this.onFetch,
  });
}

class QueryFunctionContext<TQueryKey extends QueryKey,
    TPageParam extends dynamic> {
  TQueryKey queryKey;
  TPageParam? pageParam;
  QueryMeta? meta;

  QueryFunctionContext({
    required this.queryKey,
    this.pageParam,
    this.meta,
  });
}

class QueryOptions<TQueryFnData extends dynamic, TError extends dynamic,
    TData extends dynamic, TQueryKey extends QueryKey> {
  dynamic retry;
  dynamic retryDelay;
  QueryNetworkMode? networkMode;
  Duration? cacheTime;
  bool Function(TData? oldData, TData newData)? isDataEqual;
  QueryFunction<TQueryFnData, TQueryKey>? queryFunction;
  String? queryHash;
  TQueryKey? queryKey;
  QueryKeyHashFunction<TQueryKey>? queryKeyHashFunction;
  dynamic initialData;
  dynamic initialDataUpdatedAt;
  QueryBehavior<TQueryFnData, TError, TData, TQueryKey>? behavior;
  bool? structuralSharing;
  GetPreviousPageParamFunction<TQueryFnData>? getPreviousPageParamFunction;
  GetNextPageParamFunction<TQueryFnData>? getNextPageParamFunction;
  bool? defaulted;
  QueryMeta? meta;

  QueryOptions({
    this.retry,
    this.retryDelay,
    this.networkMode,
    this.cacheTime,
    this.isDataEqual,
    this.queryFunction,
    this.queryHash,
    this.queryKey,
    this.queryKeyHashFunction,
    this.initialData,
    this.initialDataUpdatedAt,
    this.behavior,
    this.structuralSharing,
    this.getPreviousPageParamFunction,
    this.getNextPageParamFunction,
    this.defaulted,
    this.meta,
  });

  QueryOptions<TQueryFnData, TError, TData, TQueryKey> copyWith({
    dynamic retry,
    dynamic retryDelay,
    QueryNetworkMode? networkMode,
    Duration? cacheTime,
    bool Function(TData? oldData, TData newData)? isDataEqual,
    QueryFunction<TQueryFnData, TQueryKey>? queryFunction,
    String? queryHash,
    TQueryKey? queryKey,
    QueryKeyHashFunction<TQueryKey>? queryKeyHashFunction,
    TData? initialData,
    DateTime? initialDataUpdatedAt,
    QueryBehavior<TQueryFnData, TError, TData, TQueryKey>? behavior,
    bool? structuralSharing,
    GetPreviousPageParamFunction<TQueryFnData>? getPreviousPageParamFunction,
    GetNextPageParamFunction<TQueryFnData>? getNextPageParamFunction,
    bool? defaulted,
    QueryMeta? meta,
  }) {
    return QueryOptions<TQueryFnData, TError, TData, TQueryKey>(
      retry: retry ?? this.retry,
      retryDelay: retryDelay ?? this.retryDelay,
      networkMode: networkMode ?? this.networkMode,
      cacheTime: cacheTime ?? this.cacheTime,
      isDataEqual: isDataEqual ?? this.isDataEqual,
      queryFunction: queryFunction ?? this.queryFunction,
      queryHash: queryHash ?? this.queryHash,
      queryKey: queryKey ?? this.queryKey,
      queryKeyHashFunction: queryKeyHashFunction ?? this.queryKeyHashFunction,
      initialData: initialData ?? this.initialData,
      initialDataUpdatedAt: initialDataUpdatedAt ?? this.initialDataUpdatedAt,
      behavior: behavior ?? this.behavior,
      structuralSharing: structuralSharing ?? this.structuralSharing,
      getPreviousPageParamFunction:
          getPreviousPageParamFunction ?? this.getPreviousPageParamFunction,
      getNextPageParamFunction:
          getNextPageParamFunction ?? this.getNextPageParamFunction,
      defaulted: defaulted ?? this.defaulted,
      meta: meta ?? this.meta,
    );
  }
}

class QueryConfig<TQueryFnData, TError, TData, TQueryKey extends QueryKey> {
  QueryCache cache;
  TQueryKey queryKey;
  String queryHash;
  Logger? logger;
  QueryOptions<TQueryFnData, TError, TData, TQueryKey>? options;
  QueryOptions<TQueryFnData, TError, TData, TQueryKey>? defaultOptions;
  QueryState<TData, TError>? state;
  QueryMeta? meta;

  QueryConfig({
    required this.cache,
    required this.queryKey,
    required this.queryHash,
    this.logger,
    this.options,
    this.defaultOptions,
    this.state,
    this.meta,
  });
}

enum DispatchAction {
  continueAction,
  error,
  failed,
  fetch,
  invalidate,
  pause,
  setState,
  success
}

class SetStateOptions {
  dynamic meta;
  SetStateOptions({this.meta});
}

class Query<TQueryFunctionData extends dynamic, TError extends dynamic,
    TData extends dynamic, TQueryKey extends QueryKey> extends Removable {
  late TQueryKey queryKey;
  late String queryHash;
  late QueryOptions<TQueryFunctionData, TError, TData, TQueryKey> options;
  late QueryState<TData, TError> initialState;
  QueryState<TData, TError>? revertState;
  late QueryState<TData, TError> state;
  QueryMeta? meta;
  bool? isFetchingOptimistic;

  late QueryCache _cache;
  late Logger _logger;
  Future<TData>? _future;
  Retryer<TData>? _retryer;
  final List<QueryObserver> _observers = [];
  QueryOptions<TQueryFunctionData, TError, TData, TQueryKey>? _defaultOptions;
  bool abortSignalConsumed = false;

  Query(QueryConfig<TQueryFunctionData, TError, TData, TQueryKey> config) {
    _defaultOptions = config.defaultOptions;
    setOptions(config.options);
    _cache = config.cache;
    _logger = config.logger ?? defaultLogger;
    queryKey = config.queryKey;
    queryHash = config.queryHash;
    initialState = config.state ?? getDefaultState(options);
    state = initialState;
    meta = config.meta;
  }

  void setOptions(
      QueryOptions<TQueryFunctionData, TError, TData, TQueryKey>? options) {
    this.options = _defaultOptions?.copyWith(
          retry: options?.retry,
          retryDelay: options?.retryDelay,
          networkMode: options?.networkMode,
          cacheTime: options?.cacheTime,
          isDataEqual: options?.isDataEqual,
          queryFunction: options?.queryFunction,
          queryHash: options?.queryHash,
          queryKey: options?.queryKey,
          queryKeyHashFunction: options?.queryKeyHashFunction,
          initialData: options?.initialData,
          initialDataUpdatedAt: options?.initialDataUpdatedAt,
        ) ??
        QueryOptions();

    meta = options?.meta;
    updateCacheTime(this.options.cacheTime);
  }

  // This is called for garbage collection by the [Removable] class.
  @override
  void optionalRemove() {
    if (_observers.isNotEmpty && state.fetchStatus == FetchStatus.idle) {
      _cache.remove(this);
    }
  }

  TData setData(
    TData newData,
    SetDataOptions? options,
  ) {
    final data = replaceData(state.data, newData, this.options);

    // Set data and mark it as cached
    dispatch(DispatchAction.success, {
      'data': data,
      'dataUpdatedAt': options?.updatedAt,
      'manual': options?.manual,
    });

    return data;
  }

  void setState(
      QueryState<TData, TError> state, SetStateOptions? setStateOptions) {
    dispatch(DispatchAction.setState, {
      'state': state,
      'meta': setStateOptions?.meta,
    });
  }

  Future<void> cancel(CancelOptions? options) {
    final future = _future;
    _retryer?.cancel(options);
    return future != null
        ? future.then((_) => {}).catchError((_) {})
        : Future.value();
  }

  @override
  void destroy() {
    super.destroy();

    cancel(CancelOptions(silent: true));
  }

  void reset() {
    destroy();
    setState(initialState, null);
  }

  bool isActive() {
    // TODO: After implementing observer class
    return true;
  }

  bool isDisabled() {
    // TODO: After implementing observer class
    return false;
  }

  bool isStale() {
    // TODO: After implementing observer class
    return (state.isInvalidated || state.dataUpdatedAt == null);
  }

  bool isStaleByDuration(Duration staleDuration) {
    return (state.isInvalidated ||
            state.dataUpdatedAt == null ||
            durationUntilStale(
                    state.dataUpdatedAt ?? DateTime.now(), staleDuration)
                .isNegative
        ? true
        : false);
  }

  void onOnline() {
    // TODO: After implementing observer class
  }

  void addObserver(QueryObserver observer) {
    if (_observers.contains(observer)) return;

    _observers.add(observer);

    // Stop the query from being garbage collected
    clearGcTimer();
    _cache.notify(
        QueryCacheNotifyEvent(event: NotifyEvent.queryObserverAdded, data: {
      'query': this,
      'observer': observer,
    }));
  }

  void removeObserver(QueryObserver observer) {
    if (!_observers.contains(observer)) return;

    _observers.remove(observer);

    // Stop the query from being garbage collected
    clearGcTimer();

    if (_observers.isEmpty) {
      // If the transport layer does not support cancellation
      // we'll let the query continue so the result can be cached
      if (_retryer != null) {
        if (abortSignalConsumed) {
          _retryer?.cancel(CancelOptions(revert: true));
        } else {
          _retryer?.cancelRetry();
        }
      }

      scheduleGc();
    }

    _cache.notify(
        QueryCacheNotifyEvent(event: NotifyEvent.queryObserverRemoved, data: {
      'query': this,
      'observer': observer,
    }));
  }

  int getObserversCount() {
    return _observers.length;
  }

  void invalidate() {
    if (state.isInvalidated == false) dispatch(DispatchAction.invalidate, null);
  }

  Future<TData> fetch(
      QueryOptions<TQueryFunctionData, TError, TData, TQueryKey>? options,
      FetchOptions? fetchOptions) async {
    if (state.fetchStatus != FetchStatus.idle) {
      if (state.dataUpdatedAt != null && fetchOptions?.cancelRefetch != null) {
        // Silently cancel current fetch if the user wants to cancel refetches
        cancel(CancelOptions(silent: true));
      } else if (_future != null) {
        // make sure that retries that were potentially cancelled due to unmounts can continue
        _retryer?.continueRetry();
        // Return current Future if we are already fetching
        return _future as Future<TData>;
      }
    }

    // Update config if passed, otherwise the config from the last execution is used
    if (options != null) {
      setOptions(options);
    }

    // Use the options from the first observer with a query function if no function is found.
    // This can happen when the query is hydrated or created with setQueryData.
    if (this.options.queryFunction == null) {
      // TODO: After implementing observer class
    }

    final queryFnContext =
        QueryFunctionContext<TQueryKey, void>(queryKey: queryKey, meta: meta);

    Future<TQueryFunctionData> fetchFn() {
      if (this.options.queryFunction == null) {
        return Future.error(Exception('Missing queryFn'));
      }
      abortSignalConsumed = false;
      return this.options.queryFunction?.call(queryFnContext)
          as Future<TQueryFunctionData>;
    }

    final FetchContext<TQueryFunctionData, TError, TData, TQueryKey> context =
        FetchContext(
      fetchOptions: fetchOptions,
      queryOptions: this.options,
      queryKey: queryKey,
      state: state,
      fetchFn: fetchFn,
      meta: meta,
    );

    this.options.behavior?.onFetch(context);

    // Store state in case the current fetch needs to be reverted
    revertState = state;

    // Set to fetching state if not already in it
    if (state.fetchStatus == FetchStatus.idle ||
        state.fetchMeta != context.fetchOptions?.meta) {
      dispatch(DispatchAction.fetch, {
        'meta': context.fetchOptions?.meta,
      });
    }

    void onError(dynamic error) {
      enforceTypes([TError, CancelOptions], error, 'error');
      // Optimistically update state if needed
      if (error.runtimeType != CancelledError && error.silent == true) {
        dispatch(DispatchAction.error, error);
      }

      if (error.runtimeType != CancelledError) {
        // Notify cache callback
        // TODO: After implementing observer class

        _logger.error(error);
      }

      if (isFetchingOptimistic != null) {
        // Schedule query gc after fetching
        scheduleGc();
      }
      isFetchingOptimistic = false;
    }

    _retryer = Retryer(
      fn: context.fetchFn as Future<TData> Function(),
      continueFn: () => dispatch(DispatchAction.continueAction, null),
    );
  }

  QueryState<TData, TError> reducer(
      QueryState<TData, TError> state, DispatchAction action, dynamic data) {
    switch (action) {
      case DispatchAction.failed:
        return state.copyWith(
          fetchFailureCount: state.fetchFailureCount + 1,
        );
      case DispatchAction.pause:
        return state.copyWith(
          fetchStatus: FetchStatus.paused,
        );

      case DispatchAction.continueAction:
        return state.copyWith(
          fetchStatus: FetchStatus.fetching,
        );
      case DispatchAction.fetch:
        final baseUpdate = state.copyWith(
          fetchFailureCount: 0,
          fetchMeta: data['meta'],
          fetchStatus: canFetch(options.networkMode)
              ? FetchStatus.fetching
              : FetchStatus.paused,
        );
        return state.dataUpdatedAt == null
            ? baseUpdate.copyWith(
                error: null,
                status: QueryStatus.loading,
              )
            : baseUpdate;

      case DispatchAction.success:
        final baseUpdate = state.copyWith(
          data: data['data'],
          dataUpdateCount: state.dataUpdateCount + 1,
          dataUpdatedAt: data['dataUpdatedAt'] ?? DateTime.now(),
          error: null,
          isInvalidated: false,
          status: QueryStatus.success,
        );
        return data['manual'] == false
            ? baseUpdate.copyWith(
                fetchStatus: FetchStatus.idle,
                fetchFailureCount: 0,
              )
            : baseUpdate;
      case DispatchAction.error:
        final error = data;
        if (error.runtimeType == CancelledError &&
            error.revert &&
            revertState != null) {
          return revertState as QueryState<TData, TError>;
        }

        return state.copyWith(
          error: error as TError,
          errorUpdateCount: state.errorUpdateCount + 1,
          errorUpdatedAt: DateTime.now(),
          fetchFailureCount: state.fetchFailureCount + 1,
          fetchStatus: FetchStatus.idle,
          status: QueryStatus.error,
        );
      case DispatchAction.invalidate:
        return state.copyWith(
          isInvalidated: true,
        );
      case DispatchAction.setState:
        return data['state'] as QueryState<TData, TError>;
    }
  }

  void dispatch(DispatchAction action, dynamic data) {
    state = reducer(state, action, data);
    NotifyManager().batch(
      () => _observers.forEach(
        (observer) => observer.onQueryUpdate(action, data),
      ),
    );
  }
}

QueryState<TData, TError>
    getDefaultState<TQueryFnData, TError, TData, TQueryKey>(
        QueryOptions<TQueryFnData, TError, TData, TQueryKey> options) {
  enforceTypes([Function, TData, Null], options.initialData, 'initialData');
  enforceTypes([Function, DateTime, Null], options.initialDataUpdatedAt,
      'initialDataUpdatedAt');

  final data = options.initialData.runtimeType == Function
      ? options.initialData()
      : options.initialData;

  final hasInitialData = options.initialData != null;

  final initialDataUpdatedAt = hasInitialData
      ? options.initialDataUpdatedAt.runtimeType == Function
          ? options.initialDataUpdatedAt()
          : options.initialDataUpdatedAt
      : 0;

  final hasData = data != null;

  return QueryState(
      data: data as TData,
      dataUpdateCount: 0,
      dataUpdatedAt: hasData ? initialDataUpdatedAt ?? DateTime.now() : 0,
      error: null,
      errorUpdateCount: 0,
      errorUpdatedAt: DateTime.now(),
      fetchFailureCount: 0,
      fetchMeta: null,
      isInvalidated: false,
      status: hasData ? QueryStatus.success : QueryStatus.loading,
      fetchStatus: FetchStatus.idle);
}

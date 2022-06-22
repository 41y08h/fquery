import 'package:fquery/fquery/core/logger.dart';
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

typedef QueryFunction<T extends dynamic, TQueryKey extends dynamic> = Future<T>
    Function(QueryFunctionContext<TQueryKey, dynamic> context);
typedef QueryMeta = Map<String, dynamic>;
typedef QueryKeyHashFunction<TQueryKey extends QueryKey> = String Function(
    TQueryKey queryKey);

enum QueryStatus { loading, error, success }

enum FetchStatus { fetching, paused, idle }

class QueryState<TData extends dynamic, TError extends dynamic> {
  TData? data;
  int dataUpdateCount;
  DateTime dataUpdatedAt;
  TError? error;
  int errorUpdateCount;
  DateTime errorUpdatedAt;
  int fetchFailureCount;
  dynamic fetchMeta;
  bool isInvalidated;
  QueryStatus status;
  FetchStatus fetchStatus;

  QueryState({
    this.data,
    this.error,
    required this.dataUpdateCount,
    required this.dataUpdatedAt,
    required this.errorUpdateCount,
    required this.errorUpdatedAt,
    required this.fetchFailureCount,
    required this.fetchMeta,
    required this.isInvalidated,
    required this.status,
    required this.fetchStatus,
  });
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
  Future? _future;
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

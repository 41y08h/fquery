// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/src/hooks/use_query.dart';
import 'package:fquery/src/hooks/use_query_client.dart';
import 'package:fquery/src/observer.dart';
import 'package:fquery/src/queries_observer.dart';
import 'package:fquery/src/query.dart';

class UseQueriesOptions<TData, TError> extends UseQueryOptions<TData, TError> {
  final QueryKey queryKey;
  final QueryFn<TData> fetcher;

  UseQueriesOptions({
    required this.queryKey,
    required this.fetcher,
    super.enabled = true,
    super.cacheDuration,
    super.refetchInterval,
    super.refetchOnMount,
    super.staleDuration,
    super.retryCount,
    super.retryDelay,
  });
}

List<UseQueryResult<TData, TError>> useQueries<TData, TError>(
  List<UseQueriesOptions<TData, TError>> options,
) {
  final client = useQueryClient();
  final observer = useMemoized(
    () => QueriesObserver<TData, TError>(
      client: client,
    ),
  );

  useListenable(observer);

  useEffect(() {
    observer.setOptions(options);
    return null;
  }, [options.lock]);

  useEffect(() {
    return () {
      observer.destroy();
    };
  }, [observer]);

  return observer.observers
      .map(
        (observer) => UseQueryResult(
          data: observer.query.state.data,
          dataUpdatedAt: observer.query.state.dataUpdatedAt,
          error: observer.query.state.error,
          errorUpdatedAt: observer.query.state.errorUpdatedAt,
          isError: observer.query.state.isError,
          isLoading: observer.query.state.isLoading,
          isFetching: observer.query.state.isFetching,
          isSuccess: observer.query.state.isSuccess,
          status: observer.query.state.status,
          refetch: observer.fetch,
          isInvalidated: observer.query.state.isInvalidated,
          isRefetchError: observer.query.state.isRefetchError,
        ),
      )
      .toList();
}

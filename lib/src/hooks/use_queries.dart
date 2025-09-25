// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/src/hooks/use_query.dart';
import 'package:fquery/src/hooks/use_query_client.dart';
import 'package:fquery/src/observers/queries_observer.dart';
import 'package:fquery/src/data_classes/query_options.dart';

List<UseQueryResult<TData, TError>> useQueries<TData, TError extends Exception>(
  List<QueryOptions<TData, TError>> options,
) {
  final client = useQueryClient();
  final observer = useRef(
    QueriesObserver<TData, TError>(
      client: client,
    ),
  ).value;

  useListenable(observer);

  useEffect(() {
    observer.setOptions(options);
    return null;
  }, options);

  useEffect(() {
    return () {
      observer.dispose();
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

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/src/models/query_result.dart';
import 'package:fquery/src/hooks/use_query_client.dart';
import 'package:fquery/src/observers/queries_observer.dart';
import 'package:fquery/src/models/query_options.dart';

List<QueryResult<TData, TError>> useQueries<TData, TError extends Exception>(
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
        (observer) => QueryResult(
          data: observer.query.data,
          dataUpdatedAt: observer.query.dataUpdatedAt,
          error: observer.query.error,
          errorUpdatedAt: observer.query.errorUpdatedAt,
          isError: observer.query.isError,
          isLoading: observer.query.isLoading,
          isFetching: observer.query.isFetching,
          isSuccess: observer.query.isSuccess,
          status: observer.query.status,
          refetch: observer.fetch,
          isInvalidated: observer.query.isInvalidated,
          isRefetchError: observer.query.isRefetchError,
        ),
      )
      .toList();
}

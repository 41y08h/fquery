import 'package:fquery/src/models/query.dart';
import 'package:fquery/src/observers/observer.dart';

/// Query options
class QueryOptions<TData, TError extends Exception>
    extends BaseQueryOptions<TData, TError> {
  /// The query function used to fetch the data
  final QueryFn<TData> queryFn;

  /// Creates a new [QueryOptions] instance.
  QueryOptions({
    required super.queryKey,
    required this.queryFn,
    super.cacheDuration,
    super.enabled,
    super.refetchInterval,
    super.refetchOnMount,
    super.retryCount,
    super.retryDelay,
    super.staleDuration,
  });
}

import 'package:fquery/fquery/core/query_cache.dart';
import 'package:fquery/fquery/core/query_client.dart';
import 'package:fquery/fquery/core/subscribable.dart';
import 'package:fquery/fquery/core/types.dart';

typedef QueryObserverListener<TData, TError> = void Function(
    QueryObserverResult result);

class QueryObserver<TData extends dynamic, TError extends dynamic,
    TQueryKey extends QueryKey> extends Subscribable<QueryObserverListener> {
  late QueryClient _client;
  QueryObserver({required QueryClient client}) {
    client = client;
  }
}

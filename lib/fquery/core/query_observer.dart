import 'package:fquery/fquery/core/query.dart';
import 'package:fquery/fquery/core/query_cache.dart';
import 'package:fquery/fquery/core/query_client.dart';
import 'package:fquery/fquery/core/subscribable.dart';
import 'package:fquery/fquery/core/types.dart';

typedef QueryObserverListener<TData, TError> = void Function(
    QueryObserverResult result);

class QueryObserver<TQueryFnData extends dynamic, TData extends dynamic,
    TError extends dynamic, TQueryKey extends QueryKey> extends Subscribable {
  late QueryClient _client;
  QueryObserver({required QueryClient client}) {
    client = client;
  }

  void onQueryUpdate(DispatchAction action, dynamic data) {}
}

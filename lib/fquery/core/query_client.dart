import 'package:fquery/fquery/core/query_cache.dart';

class QueryClient {
  final QueryCache _queryCache;
  QueryClient({
    QueryCache? queryCache,
  }) : _queryCache = queryCache ?? QueryCache();
}

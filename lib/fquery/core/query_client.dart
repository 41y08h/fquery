import 'package:fquery/fquery/core/online_manager.dart';
import 'package:fquery/fquery/core/query_cache.dart';

class QueryClient {
  final QueryCache _queryCache;
  QueryClient({
    QueryCache? queryCache,
  }) : _queryCache = queryCache ?? QueryCache();

  void mount() {
    OnlineManager().addListener(
      () => {_queryCache.onOnline()},
    );
  }
}

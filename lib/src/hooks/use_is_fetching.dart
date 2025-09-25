import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

/// Hook to get the number of active fetches across all queries.
int useIsFetching() {
  final client = useQueryClient();
  final count = useListenableSelector(
      client.queryCache,
      () => client.queryCache.queries.entries
          .where((queryMap) => queryMap.value.isFetching)
          .length);

  return count;
}

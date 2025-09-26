import 'package:fquery/fquery.dart';
import 'package:fquery/src/hooks/use_observable_selector.dart';

/// Hook to get the number of active fetches across all queries.
int useIsFetching() {
  final client = useQueryClient();
  final count = useObservableSelector(
    client.queryCache,
    () => client.queryCache.queries.entries
        .where((queryMap) => queryMap.value.isFetching)
        .length,
  );
  return count;
}

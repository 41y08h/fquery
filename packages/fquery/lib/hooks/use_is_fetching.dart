import 'package:flutter/cupertino.dart';
import 'package:fquery/widgets/cache_provider.dart';
import '../src/use_observable_selector.dart';

/// Hook to get the number of active fetches across all queries.
int useIsFetching(BuildContext context) {
  final cache = CacheProvider.get(context);
  final count = useObservableSelector(
    cache,
    () => cache.queries.entries
        .where((queryMap) => queryMap.value.isFetching)
        .length,
  );
  return count;
}

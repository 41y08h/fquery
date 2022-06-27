import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery/src/observer.dart';
import 'package:fquery/src/query.dart';

QueryState<TData, TError> useQuery<TData, TError>(
  String queryKey,
  Future<TData> Function() fetcher, {
  QueryOptions? options,
}) {
  final client = useQueryClient();

  final queryOptions = useMemoized(
    () => options,
    [
      options?.enabled,
      options?.refetchOnMount,
      options?.cacheDuration,
      options?.staleDuration,
    ],
  );
  final observer = useMemoized(
    () => Observer<TData, TError>(
      queryKey,
      fetcher,
      client: client,
      options: queryOptions,
    ),
    [queryKey],
  );
  // This subscribes to the observer
  useListenable(observer);

  // Propagate the options changes to the observer
  useEffect(() {
    if (queryOptions == null) return;
    observer.onOptionsChanged(queryOptions);
    return null;
  }, [queryOptions]);

  useEffect(() {
    return () {
      observer.cleanup();
    };
  }, []);

  return observer.query.state;
}

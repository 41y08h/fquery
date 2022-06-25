import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/fquery.dart';

QueryState<TData, TError> useQuery<TData, TError>(
  String queryKey,
  Future<TData> Function() fetcher, {
  bool enabled = true,
  Duration? refreshDuration,
}) {
  final client = useQueryClient();
  final query = useListenable(client.buildQuery<TData, TError>(queryKey));
  final isFetching = useState(false);

  final fetch = useCallback(() async {
    if (enabled == false || isFetching.value) return;

    final staleTime =
        query.state.dataUpdatedAt?.add(refreshDuration ?? Duration.zero);
    final isDataFresh = staleTime?.isAfter(DateTime.now()) ?? false;
    if (isDataFresh) return;

    isFetching.value = true;
    try {
      final data = await fetcher();
      query.setData(data);
    } catch (e) {
      query.setError(e as TError);
    } finally {
      isFetching.value = false;
    }
  }, [query, enabled, refreshDuration]);

  useEffect(() {
    fetch();
    return null;
  }, [fetch]);

  useEffect(() {
    if (refreshDuration == null) return null;

    final timer = Timer.periodic(refreshDuration, (timer) {
      fetch();
    });
    return () => timer.cancel();
  }, [refreshDuration, fetcher, query]);

  return query.state;
}

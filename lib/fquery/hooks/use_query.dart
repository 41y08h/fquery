import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/fquery.dart';

QueryState<TData, TError> useQuery<TData, TError>(
  String queryKey,
  Future<TData> Function() fetcher, {
  bool enabled = true,
}) {
  final client = useQueryClient();
  final query = useListenable(client.buildQuery<TData, TError>(queryKey));

  useEffect(() {
    if (!enabled) return;

    fetcher().then(query.setData).catchError((error) {
      query.setError(error as TError);
    });
    return null;
  }, [enabled, query]);

  return query.state;
}

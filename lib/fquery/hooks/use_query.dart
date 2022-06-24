import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/hooks/use_query_client.dart';
import 'package:fquery/fquery/query_observer.dart';
import 'package:fquery/fquery/types.dart';

QueryState useQuery(
  String queryKey, {
  QueryFn? queryFn,
  Duration staleDuration = Duration.zero,
  Duration? refetchInterval,
  RefetchOnReconnect refetchOnReconnect = RefetchOnReconnect.ifStale,
  dynamic Function(dynamic data)? select,
  dynamic Function(dynamic data)? transform,
  bool enabled = true,
}) {
  final queryClient = useQueryClient();
  final observer = useMemoized(
    () => QueryObserver(
      queryKey,
      client: queryClient,
      queryFn: queryFn,
      staleDuration: staleDuration,
      refetchInterval: refetchInterval,
      refetchOnReconnect: refetchOnReconnect,
      select: select,
      transform: transform,
      enabled: enabled,
    ),
  );

  return useListenable(observer).query.state;
}

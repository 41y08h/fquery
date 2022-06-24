import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/connection_status.dart';
import 'package:fquery/fquery/query_result.dart';
import 'package:fquery/fquery/types.dart';
import 'package:fquery/main.dart';

QueryResult useQuery(
  String queryKey, {
  QueryFn? fetch,
  Duration staleDuration = Duration.zero,
  Duration? refetchInterval,
  RefetchOnReconnect refetchOnReconnect = RefetchOnReconnect.ifStale,
  dynamic Function(dynamic data)? select,
  dynamic Function(dynamic data)? transform,
}) {
  final query = useListenable(
    queryClient.buildQuery(
      queryKey,
      queryFn: fetch,
      transform: transform,
    ),
  );
  final connectionStatus = useListenable(ConnectionStatus());

  useEffect(() {
    if (query.state.isLoading) {
      query.fetchData();
    }
    return null;
  }, []);

  useEffect(() {
    if (!connectionStatus.isOnline) return;
    if (refetchOnReconnect == RefetchOnReconnect.never) return;
    if (refetchOnReconnect == RefetchOnReconnect.always) {
      query.fetchData();
      return;
    } else if (refetchOnReconnect == RefetchOnReconnect.ifStale) {
      final staleTime = query.state.dataUpdatedAt?.add(staleDuration);

      if (staleTime != null ? staleTime.isBefore(DateTime.now()) : false) {
        query.fetchData();
      }
    }
    return null;
  }, [connectionStatus.isOnline]);

  useEffect(() {
    if (refetchInterval == null) return null;
    final timer = Timer.periodic(refetchInterval, (_) {
      if (!connectionStatus.isOnline) return;
      query.fetchData();
    });
    return () => timer.cancel();
  }, [refetchInterval, connectionStatus]);

  return QueryResult(query.state);
}

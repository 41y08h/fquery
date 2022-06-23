import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/connection_status.dart';
import 'package:fquery/fquery/subscribable.dart';

main() {
  runApp(const App());
}

class QueryClient {
  final Map<String, Query> queries = {};

  Query<TData, TError>? getQuery<TData, TError>(String queryKey) {
    return queries[queryKey] as Query<TData, TError>;
  }

  Query<TData, TError> addQuery<TData, TError>(
      String queryKey, Query<TData, TError> query) {
    if (queries[queryKey] != null) {
      return queries[queryKey] as Query<TData, TError>;
    }
    return queries[queryKey] = query;
  }

  Query<TData, TError> buildQuery<TData, TError>(
      String queryKey, Future<TData> Function() getData) {
    return getQuery(queryKey) ??
        addQuery(
          queryKey,
          Query<TData, TError>(
            queryKey: queryKey,
            getData: getData,
            state: QueryState(),
          ),
        );
  }

  void setQueryData<TData>(
      String queryKey, TData Function(TData previous) updater) {
    final query = getQuery(queryKey);
    query?.state.data = updater(query.state.data);
    query?.notifyListeners();
  }
}

class QueryState<TData extends dynamic, TError extends dynamic> {
  bool isLoading;
  bool isFetching;
  TData? data;
  TError? error;
  DateTime? dataUpdatedAt;
  DateTime? errorUpdatedAt;

  QueryState({
    this.isLoading = true,
    this.isFetching = true,
    this.data,
    this.error,
    this.dataUpdatedAt,
    this.errorUpdatedAt,
  });
}

class Query<TData, TError> extends Subscribable {
  final String queryKey;
  QueryState<TData, TError> state;
  Future<TData> Function() getData;

  Query({
    required this.queryKey,
    required this.state,
    required this.getData,
  });

  Future<void> fetchData() async {
    state.isLoading = state.data != null ? false : true;
    state.isFetching = true;
    notifyListeners();

    try {
      state.data = await getData();
      state.dataUpdatedAt = DateTime.now();
      notifyListeners();
    } catch (e) {
      state.error = e as TError;
      state.errorUpdatedAt = DateTime.now();
      notifyListeners();
    } finally {
      state.isLoading = false;
      state.isFetching = false;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    for (final listener in listeners) {
      listener();
    }
  }
}

final queryState = QueryClient();

enum RefetchOnReconnect {
  always,
  ifStale,
  never,
}

QueryState<TData, TError> useQuery<TData, TError>(
  String queryKey,
  Future<TData> Function() getData, {
  Duration staleDuration = Duration.zero,
  Duration? refetchInterval,
  RefetchOnReconnect refetchOnReconnect = RefetchOnReconnect.ifStale,
}) {
  final query = useListenable(
    queryState.buildQuery<TData, TError>(queryKey, getData),
  );
  final connectionStatus = useListenable(ConnectionStatus());

  useEffect(() {
    if (query.state.isLoading) {
      query.fetchData();
    }
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
  }, [connectionStatus.isOnline]);

  useEffect(() {
    if (refetchInterval == null) return null;
    final timer = Timer.periodic(refetchInterval, (_) {
      query.fetchData();
    });
    return () => timer.cancel();
  }, [refetchInterval]);
  return query.state;
}

class App extends HookWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Page1(),
    );
  }
}

class Page1 extends HookWidget {
  const Page1({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final query = useQuery(
      'names',
      () => Future.delayed(
        const Duration(seconds: 1),
        () => Random().nextInt(10),
      ),
      refetchInterval: const Duration(seconds: 8),
      refetchOnReconnect: RefetchOnReconnect.ifStale,
      staleDuration: const Duration(seconds: 5),
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(builder: (context) {
              if (query.isLoading) {
                return const Text('Loading...');
              }
              if (query.error != null) {
                return Text('Error: ${query.error}');
              }
              return Text('Data: ${query.data}');
            }),
            TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Page2(),
                    ),
                  );
                },
                child: const Text("Navigate"))
          ],
        ),
      ),
    );
  }
}

class Page2 extends HookWidget {
  const Page2({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final query = useQuery(
      'names',
      () => Future.delayed(
        const Duration(seconds: 1),
        () => Random().nextInt(10),
      ),
      refetchInterval: const Duration(seconds: 3),
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(builder: (context) {
              if (query.isLoading) {
                return const Text('Loading...');
              }
              if (query.error != null) {
                return Text('Error: ${query.error}');
              }
              return Text('Data: ${query.data}');
            }),
            TextButton(
                onPressed: () {
                  queryState.setQueryData<int>(
                    'names',
                    (previous) => 1,
                  );
                },
                child: const Text("Remove last")),
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}

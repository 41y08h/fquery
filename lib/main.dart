import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/connection_status.dart';
import 'package:fquery/fquery/query_client_provider.dart';
import 'package:fquery/fquery/types.dart';

main() {
  runApp(const App());
}

class QueryClient {
  final Map<String, Query> queries = {};
  final QueryClientDefaultOptions? defaultOptions;
  QueryClient({this.defaultOptions});

  Query? getQuery<TData, TError>(String queryKey) {
    return queries[queryKey];
  }

  Query addQuery<TData, TError>(String queryKey, Query query) {
    if (queries[queryKey] != null) {
      return queries[queryKey] as Query;
    }
    return queries[queryKey] = query;
  }

  Query buildQuery(String queryKey, QueryFn? queryFn) {
    final queryFunction = queryFn ?? defaultOptions?.queryFn;
    if (queryFunction == null) {
      throw Exception('QueryFn is missing');
    }

    return (getQuery(queryKey) ??
        addQuery(
          queryKey,
          Query(
            queryKey: queryKey,
            queryFn: queryFunction,
            state: QueryState(),
          ),
        ));
  }

  void invalidateQueries(List<String> queryKeys) {
    for (var queryKey in queryKeys) {
      final query = getQuery(queryKey);
      if (query != null) {
        query.invalidate();
      }
    }
  }

  void setQueryData<TData>(
      String queryKey, TData Function(TData previous) updater) {
    final query = getQuery(queryKey);
    query?.state.data = updater(query.state.data);
    query?.notifyListeners();
  }
}

class Query extends ChangeNotifier {
  final String queryKey;
  QueryState state;
  QueryFn<dynamic> queryFn;

  Query({
    required this.queryKey,
    required this.state,
    required this.queryFn,
  });

  Future<void> fetchData() async {
    state = state.copyWith(
      isLoading: state.data != null ? false : true,
      isFetching: true,
    );
    notifyListeners();

    try {
      state = state.copyWith(
        data: await queryFn(),
        dataUpdatedAt: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      state = state.copyWith(
        error: e,
        errorUpdatedAt: DateTime.now(),
      );
      notifyListeners();
    } finally {
      state = state.copyWith(
        isFetching: false,
        isLoading: false,
      );
      notifyListeners();
    }
  }

  void invalidate() {
    state.copyWith(
      isStale: true,
    );
    notifyListeners();
    fetchData();
  }
}

final queryClient = QueryClient(
  defaultOptions: QueryClientDefaultOptions(
    queryFn: () async {
      print("default queryFn called");
      await Future.delayed(const Duration(seconds: 1));
      return 'data is here ${Random().nextInt(10)}';
    },
  ),
);

QueryState useQuery(
  String queryKey, {
  QueryFn? fetch,
  Duration staleDuration = Duration.zero,
  Duration? refetchInterval,
  RefetchOnReconnect refetchOnReconnect = RefetchOnReconnect.ifStale,
}) {
  final query = useListenable(
    queryClient.buildQuery(queryKey, fetch),
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
    final query = useQuery('home');

    return QueryClientProvider(
      queryClient: queryClient,
      child: MaterialApp(
        title: '${query.data}',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const Page1(),
      ),
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
      fetch: () async {
        await Future.delayed(const Duration(seconds: 1));
        return ['a', 'b', 'c'];
      },
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
    final queryClient = useQueryClient();
    final query = useQuery(
      'names',
      fetch: () => Future.delayed(
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
                  queryClient.setQueryData<int>(
                    'names',
                    (previous) => 1,
                  );
                },
                child: const Text("Remove last")),
            TextButton(
                onPressed: () {
                  queryClient.invalidateQueries(['home']);
                },
                child: const Text("Refetch home query")),
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

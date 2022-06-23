import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

main() {
  runApp(const App());
}

class Subscribable extends Listenable {
  final listeners = <Function>[];

  @override
  void addListener(Function listener) {
    listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
  }
}

class QueryState {
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
            data: null,
            error: null,
            isLoading: true,
            queryKey: queryKey,
            getData: getData,
          ),
        );
  }
}

class Query<TData, TError> extends Subscribable {
  final String queryKey;
  bool isLoading;
  TData? data;
  dynamic error;
  Future<TData> Function() getData;

  Query({
    required this.queryKey,
    required this.isLoading,
    required this.data,
    required this.error,
    required this.getData,
  });

  Future<void> fetchData() async {
    isLoading = true;
    notifyListeners();

    try {
      data = await getData();
      notifyListeners();
    } catch (e) {
      error = e;
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void notifyListeners() {
    for (final listener in listeners) {
      listener();
    }
  }
}

final queryState = QueryState();

Query<TData, TError> useQuery<TData, TError>(
    String queryKey, Future<TData> Function() getData) {
  final query =
      useListenable(queryState.buildQuery<TData, TError>(queryKey, getData));

  useEffect(() {
    if (query.isLoading) {
      query.fetchData();
    }
  }, []);
  return query;
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
      () => Future.delayed(const Duration(seconds: 1), () => ['a', 'b']),
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
    final query = useQuery('names',
        () => Future.delayed(const Duration(seconds: 1), () => ['a', 'b']));

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
                  Navigator.pop(context);
                },
                child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}

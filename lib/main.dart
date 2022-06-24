import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/fquery.dart';
import 'package:fquery/fquery/query_client_provider.dart';
import 'package:fquery/models/todo.dart';

main() {
  runApp(const App());
}

final queryClient = QueryClient(
  defaultOptions: QueryClientDefaultOptions(
    queryFn: (queryKey) async {
      final res = await Dio(
        BaseOptions(
          baseUrl: 'https://jsonplaceholder.typicode.com',
        ),
      ).get(queryKey);
      return res.data;
    },
  ),
);

class App extends HookWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(
    BuildContext context,
  ) {
    return QueryClientProvider(
      queryClient: queryClient,
      child: MaterialApp(
        title: 'FQuery v1 is here',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends HookWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final query = useQuery(
      '/todos',
      transform: (data) {
        final List<Todo> todos = [];
        for (var item in data) {
          todos.add(Todo.fromJson(item));
        }
        return todos;
      },
      refetchInterval: const Duration(seconds: 4),
    );

    return Scaffold(
      body: Center(
        child: Text(
          query.status.toString(),
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}

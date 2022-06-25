import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/fquery.dart';
import 'package:fquery/fquery/query_client_provider.dart';
import 'package:fquery/models/todo.dart';

main() {
  runApp(const App());
}

final queryClient = QueryClient();

class App extends HookWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryClientProvider(
      queryClient: queryClient,
      child: MaterialApp(
          title: 'FQuery v1 is here',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const HomePage(),
            '/todo': (context) => const TodoPage(),
          }),
    );
  }
}

class HomePage extends HookWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final query = useQuery('/todos', () async {
      final res = await Dio().get('https://jsonplaceholder.typicode.com/todos');
      final List<Todo> todos = [];
      for (var item in res.data) {
        todos.add(Todo.fromJson(item));
      }
      return todos;
    });

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Builder(builder: (context) {
                if (query.isLoading) {
                  return const CircularProgressIndicator();
                } else if (query.isError) {
                  return Text(query.error.toString());
                } else {
                  return ListView.builder(
                    itemCount: query.data?.length,
                    itemBuilder: (context, index) {
                      final todo = query.data?[index] as Todo;
                      return ListTile(
                        onTap: () {
                          Navigator.pushNamed(context, '/todo',
                              arguments: todo.id);
                        },
                        title: Text(todo.title),
                        subtitle: Text(todo.userId.toString()),
                      );
                    },
                  );
                }
              }),
            ),
          ),
        ],
      ),
    );
  }
}

Future<Todo> fetchTodo(int id) async {
  final res = await Dio().get('https://jsonplaceholder.typicode.com/todos/$id');
  throw Exception('dfsdf');
  return Todo.fromJson(res.data);
}

class TodoPage extends HookWidget {
  const TodoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final id = useState(ModalRoute.of(context)?.settings.arguments as int);
    final enabled = useState(false);
    final query = useQuery(
      '/todos/${id.value}',
      () => fetchTodo(id.value),
      enabled: enabled.value,
    );

    return Scaffold(
        body: Center(
      child: Column(
        children: [
          // Enable button
          RaisedButton(
            child: const Text('Enable'),
            onPressed: () {
              enabled.value = true;
            },
          ),
          Expanded(
            child: Center(
              child: Builder(
                builder: (context) {
                  if (query.isLoading) {
                    return const CircularProgressIndicator();
                  } else if (query.isError) {
                    return Text(query.error.toString());
                  } else {
                    final todo = query.data as Todo;
                    return Text(todo.title);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

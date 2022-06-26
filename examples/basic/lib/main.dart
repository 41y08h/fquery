import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

final queryClient = QueryClient();
void main() {
  runApp(QueryClientProvider(
    queryClient: queryClient,
    child: const MaterialApp(
      home: App(),
    ),
  ));
}

class Todo {
  final int userId;
  final int id;
  final String title;
  bool completed;

  Todo({
    required this.userId,
    required this.id,
    required this.title,
    required this.completed,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      userId: json['userId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      completed: json['completed'] as bool,
    );
  }

  Todo copyWith({
    int? userId,
    int? id,
    String? title,
    bool? completed,
  }) {
    return Todo(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

Future<List<Todo>> getTodos() {
  return Dio()
      .get('https://jsonplaceholder.typicode.com/todos')
      .then((response) {
    return (response.data as List).map((todo) => Todo.fromJson(todo)).toList();
  });
}

class App extends HookWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final todos = useQuery('todos', getTodos);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FQuery'),
      ),
      body: Builder(
        builder: (context) {
          if (todos.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (todos.isError) {
            return const Center(
              child: Text('Error'),
            );
          }
          return ListView.builder(
            itemCount: todos.data?.length,
            itemBuilder: (context, index) {
              final todo = todos.data![index];
              return ListTile(
                title: Text(todo.title),
                trailing: Checkbox(
                  onChanged: (_) {},
                  value: todo.completed,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

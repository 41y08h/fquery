import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/hooks/use_query.dart';
import 'package:fquery/fquery/query_client.dart';
import 'package:fquery/fquery/query_client_provider.dart';
import 'package:fquery/fquery/types.dart';

main() {
  runApp(const App());
}

final queryClient = QueryClient(
  defaultOptions: QueryClientDefaultOptions(
    queryFn: () async {
      await Future.delayed(const Duration(seconds: 1));
      return 'data is here ${Random().nextInt(10)}';
    },
  ),
);

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

class Page1 extends HookWidget {
  const Page1({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final queryClient = useQueryClient();
    final query = useQuery(
      'todos',
      fetch: () async {
        final res =
            await Dio().get('https://jsonplaceholder.typicode.com/todos');

        final List<Todo> todos = [];
        for (var item in res.data) {
          todos.add(Todo.fromJson(item));
        }

        return todos;
      },
    );

    return Scaffold(
      body: Center(
        child: query.when<List<Todo>, dynamic>(
          loading: () => const CircularProgressIndicator(),
          error: (error) => Text("Error $error"),
          data: (data) => ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final todo = data[index];
                return ListTile(
                  title: Text(
                    todo.title,
                    style: TextStyle(
                      decoration:
                          todo.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(todo.id.toString()),
                  onTap: () {
                    queryClient.setQueryData<List<Todo>>(
                      'todos',
                      (previous) => previous
                          .map<Todo>(
                            (item) => item.id == todo.id
                                ? todo.copyWith(completed: !todo.completed)
                                : item,
                          )
                          .toList(),
                    );
                  },
                );
              }),
        ),
      ),
    );
  }
}

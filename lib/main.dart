import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/core/query_cache.dart';
import 'package:fquery/fquery/core/query_client.dart';
import 'package:fquery/fquery/fquery.dart';

class QueryClientProvider extends InheritedWidget {
  const QueryClientProvider({
    Key? key,
    required Widget child,
    required this.queryClient,
  }) : super(key: key, child: child);

  final QueryClient queryClient;

  static QueryClientProvider of(BuildContext context) {
    final QueryClientProvider? result =
        context.dependOnInheritedWidgetOfExactType<QueryClientProvider>();
    assert(result != null, 'No QueryClient found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(QueryClientProvider oldWidget) => true;
}

class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String website;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'],
      website: json['website'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'website': website,
    };
  }
}

main() {
  runApp(const App());
}

Future<List<User>> fetchUsers() async {
  final res = await Dio().get('https://jsonplaceholder.typicode.com/users');
  List<User> data = [];
  res.data.forEach((d) {
    data.add(User.fromJson(d));
  });
  return data;
}

final queryClient = QueryClient();

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryClientProvider(
      queryClient: queryClient,
      child: MaterialApp(
        title: 'FQuery',
        home: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          body: const Outer(),
        ),
      ),
    );
  }
}

class Outer extends StatelessWidget {
  const Outer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          Random().nextInt(10).toString(),
        ),
        const Expanded(child: Users()),
      ],
    );
  }
}

class Users extends HookWidget {
  const Users({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final query = useQuery(
      'users',
      () => Future.delayed(
        const Duration(seconds: 1),
        fetchUsers,
      ),
    );

    return Builder(builder: (context) {
      if (query.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView.builder(
        itemCount: query.data.length,
        itemBuilder: (context, index) {
          final user = query.data[index];
          return ListTile(
            title: Text(user.name),
            subtitle: Text(user.username),
            trailing: Text(user.email),
          );
        },
      );
    });
  }
}

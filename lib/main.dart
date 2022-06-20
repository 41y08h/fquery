import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/fquery.dart';

class QueryScope extends StatefulWidget {
  const QueryScope({Key? key, required this.child}) : super(key: key);
  final Widget child;

  @override
  State<QueryScope> createState() => _QueryScopeState();
}

class _QueryScopeState extends State<QueryScope> {
  Map<String, Query> queries = {};

  void setQueries(Map<String, Query> newQueries) {
    setState(() {
      queries = newQueries;
    });
  }

  Query<T>? get<T>(String queryKey) {
    final query = queries[queryKey];
    return query as Query<T>?;
  }

  Query<T> buildQuery<T>(
    String queryKey,
    Future<T> Function() fetch, {
    UseQueryOptions? options,
  }) {
    Query<T>? query = get<T>(queryKey);
    if (query == null) {
      query = Query<T>(
        queryKey: queryKey,
        queryFn: fetch,
        options: options ?? UseQueryOptions(),
      );
      setQueries(queries..[queryKey] = query);
    }
    return query;
  }

  @override
  Widget build(BuildContext context) {
    return QueryCache(
        child: widget.child, queries: queries, setQueries: setQueries);
  }
}

class QueryCache extends InheritedWidget {
  const QueryCache({
    Key? key,
    required Widget child,
    required this.queries,
    required this.setQueries,
  }) : super(key: key, child: child);

  final Map<String, Query> queries;
  final void Function(Map<String, Query<dynamic>> newQueries) setQueries;

  static QueryCache of(BuildContext context) {
    final QueryCache? result =
        context.dependOnInheritedWidgetOfExactType<QueryCache>();
    assert(result != null, 'No QueryCache found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(QueryCache old) => true;
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

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryScope(
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

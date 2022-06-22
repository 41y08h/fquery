import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/core/query_client.dart';

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
final counterr = Counter();

class App extends HookWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("app rebuild");

    final count = useCounter();
    return QueryClientProvider(
      queryClient: queryClient,
      child: MaterialApp(
        title: 'FQuery',
        home: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: Text(count.toString()),
          ),
          body: const Outer(),
        ),
      ),
    );
  }
}

class Outer extends HookWidget {
  const Outer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('outer rebuild');
    const count = 1;
    return Center(
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.headline4,
      ),
    );
  }
}

class Subscribable implements Listenable {
  final List<Function> _listeners = [];

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}

int useCounter() {
  final counter = useState(counterr);
  useListenable(counter.value);

  return counter.value.count;
}

class Counter extends Subscribable {
  int _count = 0;
  int get count => _count;

  Counter() {
    // increase count every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (timer) {
      print('increased');
      _count++;
      for (var listener in _listeners) {
        listener();
      }
    });
  }
}

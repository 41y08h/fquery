import 'package:basic/models/post.dart';
import 'package:basic/models/todos.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:fquery/fquery.dart';
import '../widgets/home_list_tile.dart';

Future<List<Post>> getPosts() async {
  final res = await Dio().get('https://dummyjson.com/posts');
  await MockServer.delay();
  return (res.data['posts'] as List).map((post) => Post.fromMap(post)).toList();
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch a query here so that
    // we can see it refetching in the background on posts page
    // return QueryBuilder<List, Exception>(
    //   options: QueryOptions(
    //     queryKey: QueryKey(['posts']),
    //     queryFn: getPosts,
    //     refetchInterval: const Duration(seconds: 5),
    //     enabled: false,
    //   ),
    //   builder: (context, _) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("examples"),
      ),
      child: ListView(
        children: const [
          HomeListTile(title: "Todos", route: "/todos"),
          HomeListTile(title: "Posts", route: "/posts"),
          HomeListTile(title: "Infinity", route: "/infinity"),
        ],
      ),
    );
    //   },
    // );
  }
}

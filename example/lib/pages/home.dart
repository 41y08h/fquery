// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:basic/models/post.dart';
import 'package:basic/models/todos.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../widgets/home_list_tile.dart';

Future<List<Post>> getPosts() async {
  final res = await Dio().get('https://jsonplaceholder.typicode.com/posts');
  await MockServer.delay();
  return (res.data as List).map((post) => Post.fromMap(post)).toList();
}

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch a query here so that
    // we can see it refetching in the background on posts page
    // useQuery<List<Post>, Error>(
    //   ['posts'],
    //   getPosts,
    //   refetchInterval: const Duration(seconds: 5),
    // );

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
        ));
  }
}

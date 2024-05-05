// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:basic/post.dart';
import 'package:basic/todos.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

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
    useQuery<List<Post>, Error>(
      ['posts'],
      getPosts,
      refetchInterval: const Duration(seconds: 5),
    );

    return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text("examples"),
        ),
        child: ListView(
          children: const [
            HomeListTile(title: "Todos", route: "/todos"),
            HomeListTile(title: "Posts", route: "/posts"),
          ],
        ));
  }
}

class HomeListTile extends StatelessWidget {
  final String title;
  final String route;
  const HomeListTile({
    Key? key,
    required this.title,
    required this.route,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: CupertinoListTile(
        title: Text(title),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        trailing: const Icon(CupertinoIcons.chevron_forward),
      ),
    );
  }
}

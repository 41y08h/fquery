import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

final queryClient = QueryClient();
void main() {
  runApp(
    QueryClientProvider(
      queryClient: queryClient,
      child: MaterialApp(
        theme: ThemeData.dark(),
        initialRoute: '/',
        routes: {
          '/': (context) => const Home(),
          '/post': (context) => const PostPage(),
        },
      ),
    ),
  );
}

class Post {
  final int userId;
  final int id;
  final String title;
  final String body;

  Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: json['userId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}

Future<List<Post>> getPosts() async {
  final res = await Dio().get('https://jsonplaceholder.typicode.com/posts');
  return (res.data as List)
      .map((e) => Post.fromJson(e as Map<String, dynamic>))
      .toList();
}

class Home extends HookWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final posts = useQuery(['posts'], getPosts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
      ),
      body: Builder(
        builder: (context) {
          if (posts.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (posts.isError) {
            return Center(
              child: Text(posts.error.toString()),
            );
          }
          return ListView.builder(
            itemCount: posts.data?.length,
            itemBuilder: (context, index) {
              final post = posts.data![index];

              return ListTile(
                title: Text(post.title),
                onTap: () {
                  Navigator.pushNamed(context, '/post', arguments: post.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}

Future<Post> getPost(int id) async {
  final res = await Dio().get('https://jsonplaceholder.typicode.com/posts/$id');
  return Post.fromJson(res.data);
}

class PostPage extends HookWidget {
  const PostPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    final post = useQuery(['posts', id], () => getPost(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: Builder(
        builder: (context) {
          if (post.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (post.isError) {
            return const Center(
              child: Text('Error'),
            );
          }

          return ListTile(
            title: Text(post.data!.title),
            subtitle: Text(post.data!.body),
          );
        },
      ),
    );
  }
}

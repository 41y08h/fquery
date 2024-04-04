import 'dart:math';

import 'package:basic/post.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:basic/post_page.dart';

final queryClient = QueryClient(
  defaultQueryOptions: DefaultQueryOptions(),
);

void main() {
  runApp(
    QueryClientProvider(
      queryClient: queryClient,
      child: CupertinoApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        theme: const CupertinoThemeData(
          brightness: Brightness.light,
        ),
        routes: {
          '/': (context) => const Home(),
          '/post': (context) => const PostPage(),
        },
      ),
    ),
  );
}

Future<List<Post>> getPosts() async {
  final res =
      await Dio().get<List>('https://jsonplaceholder.typicode.com/posts');
  return (res.data)!.map((p) => Post.fromMap(p)).toList();
}

class Home extends HookWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEnabled = useState(true);
    final client = useQueryClient();
    final posts = useQuery(['posts'], getPosts, enabled: isEnabled.value);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: const Row(
          children: [
            Text(
              'Posts',
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoSwitch(
              value: isEnabled.value,
              onChanged: (value) {
                isEnabled.value = value;
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: posts.refetch,
              child: const Icon(CupertinoIcons.refresh),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil),
              onPressed: () {
                client.setQueryData<List<Post>>(['posts'], (previous) {
                  return previous?.map((post) {
                        final randInt = Random().nextInt(100);
                        final title = "I've been edited and now I'm $randInt";
                        client.setQueryData<Post>(
                          ['posts', post.id],
                          (previous) => previous!.copyWith(title: title),
                        );

                        return post.copyWith(
                          title: title,
                        );
                      }).toList() ??
                      [];
                });
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Builder(
          builder: (context) {
            if (posts.isLoading) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }
            if (posts.isError) {
              return Center(
                child: Text(posts.error.toString()),
              );
            }
            return Column(
              children: [
                if (posts.isFetching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CupertinoActivityIndicator(),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: posts.data?.length,
                    itemBuilder: (context, index) {
                      final post = posts.data![index];
                      return CupertinoListTile(
                        onTap: () {
                          Navigator.pushNamed(context, '/post',
                              arguments: post.id);
                        },
                        title: Text(post.title),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

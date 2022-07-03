import 'package:basic/post.dart';
import 'package:cupertino_list_tile/cupertino_list_tile.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

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
  final res = await Dio().get('https://jsonplaceholder.typicode.com/posts');
  return (res.data as List)
      .map((e) => Post.fromJson(e as Map<String, dynamic>))
      .toList();
}

class Home extends HookWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final client = useQueryClient();
    final posts = useQuery(['posts'], getPosts);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: posts.refetch,
              child: const Icon(CupertinoIcons.refresh),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil),
              onPressed: () {
                client.setQueryData<List<Post>>(
                  ['posts'],
                  (previous) =>
                      previous
                          ?.map((post) => post.copyWith(
                                title: "This has been edited",
                              ))
                          .toList() ??
                      [],
                );
              },
            ),
          ],
        ),
        middle: const Text('Posts'),
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

                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/post',
                              arguments: post.id);
                        },
                        child: CupertinoListTile(
                          title: Text(post.title),
                        ),
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

Future<Post> getPost(int id) async {
  final res = await Dio().get('https://jsonplaceholder.typicode.com/posts/$id');
  return Post.fromJson(res.data);
}

class PostPage extends HookWidget {
  const PostPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as int;
    final isInterval = useState(false);
    final post = useQuery(
      ['posts', id],
      () => getPost(id),
      staleDuration: const Duration(hours: 1),
      refetchInterval: isInterval.value ? const Duration(seconds: 4) : null,
    );
    final client = useQueryClient();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Post'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.archivebox),
              onPressed: () {
                client.invalidateQueries(['posts', id]);
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                isInterval.value = !isInterval.value;
              },
              child: Icon(
                CupertinoIcons.refresh_circled_solid,
                color: isInterval.value
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey,
              ),
            )
          ],
        ),
      ),
      child: SafeArea(
        child: Builder(
          builder: (context) {
            if (post.isLoading) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }
            if (post.isError) {
              return const Center(
                child: Text('Error'),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (post.isFetching)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CupertinoActivityIndicator(),
                    ),
                  // Heading style text
                  Text(
                    post.data!.title,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(post.data!.body),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

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
  final res = await Dio().get('https://jsonplaceholder.typicode.com/posts');
  return (res.data as List)
      .map((e) => Post.fromJson(e as Map<String, dynamic>))
      .toList();
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                isEnabled.value = !isEnabled.value;
              },
              child: Icon(isEnabled.value
                  ? CupertinoIcons.circle_fill
                  : CupertinoIcons.circle),
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

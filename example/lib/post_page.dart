import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:basic/post.dart';
import 'package:basic/post_editor.dart';

Future<Post> getPost(int id) async {
  final res = await Dio().get('https://jsonplaceholder.typicode.com/posts/$id');
  return Post.fromMap(res.data);
}

class PostPage extends HookWidget {
  const PostPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)!.settings.arguments as int?;
    final isInterval = useState(false);
    final post = useQuery(
      ['posts', id],
      () => getPost(id ?? 1),
      staleDuration: const Duration(hours: 1),
      refetchInterval: isInterval.value ? const Duration(seconds: 4) : null,
      refetchOnMount: RefetchOnMount.stale,
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
              child: const Row(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(CupertinoIcons.archivebox),
                  ),
                  Text("Invalidate",
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                      )),
                ],
              ),
              onPressed: () {
                client.invalidateQueries(['posts', id]);
              },
            ),
            const SizedBox(width: 12.0),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                isInterval.value = !isInterval.value;
              },
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      CupertinoIcons.refresh_circled_solid,
                      color: isInterval.value
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                  Text("Refetch",
                      style: TextStyle(
                        color: isInterval.value
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey,
                      )),
                ],
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
                  PostEditor(id: post.data!.id, title: post.data!.title),
                  const SizedBox(height: 16.0),
                  Text(post.data!.title,
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      )),
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

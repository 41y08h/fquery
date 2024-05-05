import 'package:basic/post.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

Future<Post> getPost(int id) async {
  final res = await Dio().get('https://jsonplaceholder.typicode.com/posts/$id');
  return Post.fromMap(res.data);
}

class PostsPage extends HookWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = useTextEditingController(text: "1");
    final text = useState('1');

    final postsOptions = List<UseQueriesOptions<Post, Exception>>.generate(
      int.parse(text.value == "" ? "1" : text.value),
      (i) => UseQueriesOptions(
        queryKey: ['posts', i + 1],
        fetcher: () => getPost(i + 1),
        refetchOnMount: RefetchOnMount.never,
      ),
    );
    final posts = useQueries<Post, Exception>(postsOptions);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  CupertinoIcons.chevron_back,
                  size: 25,
                )),
            const Text(
              'Posts',
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Column(
            children: [
              CupertinoTextField(
                controller: t,
                keyboardType: TextInputType.number,
                onChanged: ((value) {
                  text.value = value;
                }),
              ),
              const SizedBox(
                height: 8,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, i) {
                    final e = posts[i];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.5),
                      ),
                      child: CupertinoListTile(
                        trailing:
                            e.isFetching ? const Text("fetching...") : null,
                        title: e.isLoading
                            ? const Text("loading...")
                            : Container(
                                child: e.isSuccess
                                    ? Text(e.data!.title)
                                    : const Text("Error"),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

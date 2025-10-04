import 'package:basic/models/post.dart';
import 'package:basic/models/todos.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fquery/widgets/is_fetching_builder.dart';
import 'package:fquery/widgets/queries_builder.dart';
import 'package:fquery_core/fquery_core.dart';

Future<Post> getPost(int id) async {
  final res = await Dio().get('https://dummyjson.com/posts/$id');
  await MockServer.delay();
  return Post.fromMap(res.data);
}

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final postsCountInputController = TextEditingController(text: "1");
  int text = 1;

  @override
  void dispose() {
    postsCountInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QueriesBuilder<Post, Exception>(
      options: List<QueryOptions<Post, Exception>>.generate(
        text,
        (i) => QueryOptions(
          queryKey: QueryKey(['posts', i + 1]),
          queryFn: () => getPost(i + 1),
          refetchOnMount: RefetchOnMount.never,
        ),
      ),
      builder: (context, posts) {
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
                  ),
                ),
                const Text(
                  'Posts ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              ],
            ),
            trailing: IsFetchingBuilder(builder: (context, count) {
              return Text("currently fetching $count queries");
            }),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Column(
                children: [
                  CupertinoTextField(
                    controller: postsCountInputController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final intValue = int.tryParse(value);
                      setState(() {
                        if (intValue != null) {
                          text = intValue;
                        } else {
                          text =
                              1; // Fallback to a default value if parsing fails
                        }
                      });
                    },
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
                                        : Text("Error: ${e.error.toString()}"),
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
      },
    );
  }
}

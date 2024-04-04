import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:basic/post.dart';

class PostEditor extends HookWidget {
  const PostEditor({super.key, required this.title, required this.id});

  final int id;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController(text: title);
    final queryClient = useQueryClient();

    final mutation = useMutation<String, String, String>(
      (title) async {
        await Future.delayed(const Duration(milliseconds: 500));

        // simulate an error
        if (title == "error") throw "Something went wrong!";
        return title;
      },
      onMutate: (title) => {},
      onError: (error, title) => {},
      onSuccess: (data, title) {
        queryClient.setQueryData<Post>(['posts', id], (previous) {
          return previous!.copyWith(title: title);
        });
        queryClient.setQueryData<List<Post>>(['posts'], (previous) {
          return previous!.map((post) {
            if (post.id != id) {
              return post;
            } else {
              return post.copyWith(title: title);
            }
          }).toList();
        });
      },
      onSettled: (data, error, title) => {},
    );

    useEffect(() {
      // Reset the text field when the title changes
      textController.text = title;
      return null;
    }, [title]);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: textController,
              ),
            ),
            CupertinoButton(
              onPressed: mutation.isPending
                  ? null
                  : () {
                      mutation.mutate(textController.text);
                    },
              child: const Text("Save"),
            )
          ],
        ),
        if (mutation.isError)
          Text(mutation.error!,
              style: const TextStyle(color: CupertinoColors.destructiveRed)),
      ],
    );
  }
}

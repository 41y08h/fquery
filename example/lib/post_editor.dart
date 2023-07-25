import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery_example/post.dart';

class PostEditor extends HookWidget {
  const PostEditor({super.key, required this.title, required this.id});

  final int id;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController(text: title);
    final queryClient = useQueryClient();
    final mutation = useMutation<String, String, dynamic>(
      mutationFn: (title) async {
        // This is where you would make your async call
        await Future.delayed(const Duration(milliseconds: 500));
        return title;
      },
      onMutate: (title) => {
        print("About to mutate: $title"),
      },
      onError: (error, title) => {
        print("Error: $error while saving $title"),
      },
      onSuccess: (data, title) => {
        print("Success: $data while saving $title"),
        queryClient.setQueryData<Post>(['posts', id], (previous) {
          if (previous == null) return Post(userId: 0, id: id, title: title, body: "");
          return previous.copyWith(title: title);
        })
      },
      onSettled: (data, error, title) => {
        print("Settled: $data while saving $title"),
      },
    );

    useEffect(() {
      // Reset the text field when the title changes (is invalidated or refetched in this case)
      textController.text = title;
      return null;
    }, [title]);

    return Row(
      children: [
        Expanded(
          child: CupertinoTextField(
            controller: textController,
          ),
        ),
        CupertinoButton(
          onPressed: mutation.isLoading
              ? null
              : () async {
                  print("Saving...");
                  await mutation.mutate(textController.text);
                  print("Saved!");
                },
          child: const Text("Save"),
        )
      ],
    );
  }
}

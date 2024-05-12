// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:basic/models/todos.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

class TodoListTile extends HookWidget {
  const TodoListTile({
    super.key,
    required this.todo,
  });

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final client = useQueryClient();
    final todosAPI = TodosAPI.getInstance();
    final controller = useTextEditingController(text: todo.text);
    final isEditingMode = useState(false);

    final editMutation =
        useMutation<Todo, Exception, String, void>((newText) async {
      return todosAPI.edit(todo.id, newText);
    }, onSuccess: (updatedTodo, newText, ctx) {
      isEditingMode.value = !isEditingMode.value;

      client.setQueryData<List<Todo>>(
        ['todos'],
        (previous) {
          if (previous == null) return [];
          return previous.map((e) {
            if (e.id != updatedTodo.id) return e;
            return updatedTodo;
          }).toList();
        },
      );
    });

    final markMutation = useMutation<Todo, Exception, bool, void>((mark) {
      return todosAPI.mark(todo.id, mark);
    }, onSuccess: (updatedTodo, mark, ctx) {
      client.setQueryData<List<Todo>>(
        ['todos'],
        (previous) {
          if (previous == null) return [];
          return previous.map((e) {
            if (e.id != updatedTodo.id) return e;
            return updatedTodo;
          }).toList();
        },
      );
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (isEditingMode.value)
                  Expanded(
                    child: CupertinoTextField(
                      controller: controller,
                      autofocus: true,
                    ),
                  )
                else
                  Text(
                    todo.text,
                    style: (markMutation.isPending
                            ? markMutation.variables as bool
                            : todo.isDone)
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                          )
                        : null,
                  ),
              ],
            ),
          ),
          if (isEditingMode.value)
            Row(
              children: [
                const SizedBox(
                  width: 8,
                ),
                SizedBox(
                  height: 36,
                  child: CupertinoButton(
                    padding: const EdgeInsetsDirectional.all(1),
                    color: CupertinoColors.inactiveGray,
                    onPressed: () {
                      isEditingMode.value = !isEditingMode.value;
                    },
                    child: const Icon(
                      CupertinoIcons.delete_left_fill,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                SizedBox(
                  height: 36,
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(1),
                    color: CupertinoColors.systemBlue,
                    onPressed: editMutation.isPending
                        ? null
                        : () {
                            editMutation.mutate(controller.text);
                          },
                    child: const Icon(CupertinoIcons.checkmark_alt_circle_fill),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                CupertinoButton(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 1,
                  ),
                  onPressed: () {
                    isEditingMode.value = !isEditingMode.value;
                  },
                  child: const Icon(
                    CupertinoIcons.pencil,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
                CupertinoCheckbox(
                  checkColor: markMutation.isPending
                      ? CupertinoColors.inactiveGray
                      : CupertinoColors.white,
                  inactiveColor: markMutation.isPending
                      ? CupertinoColors.inactiveGray
                      : CupertinoColors.black,
                  value: markMutation.isPending
                      ? markMutation.variables as bool
                      : todo.isDone,
                  onChanged: (value) {
                    if (value == null) return;

                    markMutation.mutate(value);
                  },
                ),
                MutationBuilder((id) async {
                  await todosAPI.delete(todo.id);
                  return id;
                }, onSuccess: (id, _, ctx) {
                  client.setQueryData<List<Todo>>(
                    ['todos'],
                    (previous) {
                      if (previous == null) return [];
                      return previous.where((e) {
                        return (e.id != id);
                      }).toList();
                    },
                  );
                }, builder: (context, mutation) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: mutation.isPending
                        ? null
                        : () {
                            mutation.mutate(todo.id);
                          },
                    child: const Icon(CupertinoIcons.delete_solid),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}

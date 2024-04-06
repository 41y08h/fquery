import 'package:basic/todos.dart';
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
        },
      ),
    ),
  );
}

class Home extends HookWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final client = useQueryClient();
    final todosAPI = TodosAPI.getInstance();
    final todos = useQuery(
      ['todos'],
      todosAPI.getAll,
      refetchOnMount: RefetchOnMount.never,
    );
    final todoInputController = useTextEditingController();
    final addTodoMutation = useMutation(todosAPI.add, onSuccess: (_, __, ___) {
      client.invalidateQueries(['todos']);
      todoInputController.clear();
    });

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: const Row(
          children: [
            Text(
              'Todos',
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: todos.refetch,
              child: const Icon(CupertinoIcons.refresh),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Builder(
          builder: (context) {
            if (todos.isLoading) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }
            if (todos.isError) {
              return Center(
                child: Text(todos.error.toString()),
              );
            }
            return Column(
              children: [
                if (todos.isFetching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CupertinoActivityIndicator(),
                  ),
                const SizedBox(
                  height: 12,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: CupertinoTextField(
                                controller: todoInputController,
                                placeholder: "Play football",
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            SizedBox(
                              height: 36,
                              child: CupertinoButton(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 36),
                                color: CupertinoColors.systemBlue,
                                onPressed: addTodoMutation.isPending
                                    ? null
                                    : () {
                                        addTodoMutation
                                            .mutate(todoInputController.text);
                                      },
                                child: const Text("Add"),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: todos.data?.length,
                          itemBuilder: (context, index) {
                            final todo = todos.data![index];
                            return TodoListTile(
                              todo: todo,
                              key: Key(todo.id.toString()),
                            );
                          },
                        ),
                      ),
                    ],
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
        useMutation<String, Todo, Exception, void>((newText) async {
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

    final markMutation = useMutation<bool, Todo, Exception, void>((mark) {
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

    final deleteMutation = useMutation<int, int, Exception, void>((id) async {
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
                    CupertinoIcons.pencil_outline,
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
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: deleteMutation.isPending
                      ? null
                      : () {
                          deleteMutation.mutate(todo.id);
                        },
                  child: const Icon(CupertinoIcons.delete_solid),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

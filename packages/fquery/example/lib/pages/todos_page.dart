import 'dart:math';
import 'package:basic/widgets/todo_list_tile.dart';
import 'package:basic/models/todos.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fquery/fquery.dart';
import 'package:fquery_core/fquery_core.dart';
import 'package:fquery_core/models/query.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  bool isEnabled = true;
  final todoInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cache = CacheProvider.get(context);
    final todosAPI = TodosAPI.getInstance();
    // final todosQuery = QueryInstance.of(
    //   context,
    //   QueryOptions(
    //     queryKey: QueryKey(['todos']),
    //     queryFn: todosAPI.getAll,
    //     refetchOnMount: RefetchOnMount.never,
    //     refetchInterval: null,
    //     enabled: isEnabled,
    //   ),
    // );

    return QueryBuilder<List<Todo>, Exception>(
      options: QueryOptions(
        queryKey: QueryKey(['todos']),
        queryFn: todosAPI.getAll,
        refetchOnMount: RefetchOnMount.never,
        enabled: isEnabled,
        staleDuration: Duration(seconds: 3),
        cacheDuration: Duration(seconds: 5),
      ),
      builder: (context, todos) {
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
                  'Todos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoSwitch(
                  value: isEnabled,
                  onChanged: (v) {
                    setState(() {
                      isEnabled = v; // Update the state and trigger a rebuild
                    });
                  },
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: todos.refetch,
                  child: const Icon(CupertinoIcons.refresh),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    cache.removeQueries<List<Todo>, Exception>(['todos']);
                  },
                  child: const Icon(CupertinoIcons.delete),
                ),
              ],
            ),
          ),
          child: SafeArea(
            child: MutationBuilder<Todo, Exception, String, List<Todo>>(
              todosAPI.add,
              onMutate: (text) async {
                FocusManager.instance.primaryFocus?.unfocus();

                final previousTodos =
                    cache.getQueryData<List<Todo>, Exception>(['todos']) ?? [];

                // Optimistically update the todo list
                cache.setQueryData<List<Todo>, Exception>(['todos'],
                    (previous) {
                  final id = Random().nextInt(pow(10, 6).toInt());
                  final newTodo = Todo(id: id, text: text);
                  return [...(previous ?? []), newTodo];
                });

                // Pass the original data as context to the next functions
                return previousTodos;
              },
              onError: (err, text, previousTodos) {
                // On failure, revert back to original data
                cache.setQueryData<List<Todo>, Exception>(
                  ['todos'],
                  (_) => previousTodos as List<Todo>,
                );
              },
              onSettled: (data, error, variables, ctx) {
                // Refetch the query anyways (either error or success)
                // Or we can manually add the returned todo (result) in the onSuccess callback
                cache.invalidateQueries(['todos']);
                todoInputController.clear();
              },
              builder: (context, addTodoMutation) {
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 36),
                                    color: CupertinoColors.systemBlue,
                                    onPressed: addTodoMutation.isPending
                                        ? null
                                        : () {
                                            addTodoMutation.mutate(
                                                todoInputController.text);
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
      },
    );
  }
}

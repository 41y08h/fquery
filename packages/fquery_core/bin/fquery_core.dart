import 'package:fquery_core/models/query_key.dart';
import 'package:fquery_core/models/query_options.dart';
import 'package:fquery_core/observers/query_observer.dart';
import 'package:fquery_core/query_cache.dart';
import 'todos.dart';

final cache = QueryCache();

void main() {
  final todos = TodosAPI.getInstance();

  final todosObserver = QueryObserver(
    cache: cache,
    options: QueryOptions(
      queryKey: QueryKey(['todos']),
      enabled: false,
      queryFn: todos.getAll,
    ),
  );

  todosObserver.subscribe(1, () {
    print(todosObserver.query.status);
  });

  todosObserver.updateOptions(
    QueryOptions(
      queryKey: QueryKey(['todos']),
      queryFn: todos.getAll,
      enabled: true,
    ),
  );

  todosObserver.initialize();
}

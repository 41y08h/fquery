import 'package:fquery/src/models/query.dart';
import 'package:fquery/src/models/query_options.dart';
import 'package:fquery/src/query_client.dart';

mixin class Observer<TData, TError extends Exception,
    TOptions extends BaseQueryOptions<TData, TError>> {
  late final QueryClient client;
  late TOptions options;
}

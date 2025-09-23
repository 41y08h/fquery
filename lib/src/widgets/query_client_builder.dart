// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/src/hooks/use_query_client.dart';
import 'package:fquery/src/query_client.dart';

@Deprecated('Use QueryClient.of(context) instead')
class QueryClientBuilder<TData, TError> extends HookWidget {
  final Widget Function(BuildContext, QueryClient) builder;
  QueryClientBuilder({
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final client = useQueryClient();

    return Builder(builder: (context) {
      return builder(context, client);
    });
  }
}

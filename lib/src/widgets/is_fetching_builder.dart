import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

/// Builder widget that provides the number of active fetches across all queries.
class IsFetchingBuilder extends HookWidget {
  /// The builder function that receives the current count of active fetches.
  final Widget Function(BuildContext context, int count) builder;

  /// Creates an [IsFetchingBuilder].
  const IsFetchingBuilder({required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    final client = QueryClient.of(context);
    final count = useListenableSelector(
      client.queryCache,
      () => client.queryCache.queries.entries
          .where((q) => q.value.state.isFetching)
          .length,
    );

    return builder(context, count);
  }
}

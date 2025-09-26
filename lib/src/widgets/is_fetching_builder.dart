import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';

/// Builder widget that provides the number of active fetches across all queries.
class IsFetchingBuilder extends StatefulWidget {
  /// The builder function that receives the current count of active fetches.
  final Widget Function(BuildContext context, int count) builder;

  /// Creates an [IsFetchingBuilder].
  const IsFetchingBuilder({required this.builder, super.key});

  @override
  State<IsFetchingBuilder> createState() => _IsFetchingBuilderState();
}

class _IsFetchingBuilderState extends State<IsFetchingBuilder> {
  @override
  void initState() {
    super.initState();
    final client = QueryClient.of(context);
    client.queryCache.addListener(hashCode, setState);
  }

  @override
  Widget build(BuildContext context) {
    final client = QueryClient.of(context);
    final count = client.queryCache.queries.entries
        .where((q) => q.value.isFetching)
        .length;

    return widget.builder(context, count);
  }
}

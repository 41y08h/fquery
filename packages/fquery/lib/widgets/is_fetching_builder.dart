import 'package:flutter/widgets.dart';
import 'package:fquery/widgets/cache_provider.dart';
import 'package:fquery_core/query_cache.dart';

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
  late QueryCache cache;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cache = CacheProvider.get(context);
    cache.subscribe(hashCode, () {
      setState(() {});
    });
  }

  @override
  void dispose() {
    cache.unsubscribe(hashCode);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = cache.isFetching;
    return widget.builder(context, count);
  }
}

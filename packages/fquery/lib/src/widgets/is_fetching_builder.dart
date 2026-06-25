import 'package:flutter/widgets.dart';
import 'package:fquery/src/widgets/cache_provider.dart';
import 'package:fquery_core/fquery_core.dart';

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
  late final QueryCache cache;
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (initialized) return;
    initialized = true;

    cache = CacheProvider.get(context)
      ..subscribe(hashCode, () {
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

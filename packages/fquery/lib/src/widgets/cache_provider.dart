import 'package:flutter/widgets.dart';
import 'package:fquery_core/query_cache.dart';

/// This can be used to provide a [QueryCache] throughout the application.
class CacheProvider extends InheritedWidget {
  final QueryCache cache;

  /// Creates a new [CacheProvider] instance.
  CacheProvider({
    super.key,
    required this.cache,
    required super.child,
  });

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => oldWidget != this;

  static QueryCache get(BuildContext context) {
    final CacheProvider? result =
        context.dependOnInheritedWidgetOfExactType<CacheProvider>();
    assert(result != null, 'QueryClientProvider not found');
    return result!.cache;
  }
}

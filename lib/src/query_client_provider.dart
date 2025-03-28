import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

class ChildWidgetWrapper extends HookWidget {
  final Widget child;
  const ChildWidgetWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final client = useQueryClient();
    useEffect(() {
      return () {
        for (var entry in client.queryCache.queries.entries) {
          final query = entry.value;
          query.cancelGarbageCollection();
        }
      };
    }, []);
    return child;
  }
}

/// This can be used to provide a [QueryClient] throughout the application.
class QueryClientProvider extends InheritedWidget {
  final QueryClient queryClient;
  QueryClientProvider({
    super.key,
    required this.queryClient,
    required Widget child,
  }) : super(child: ChildWidgetWrapper(child: child));

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => oldWidget != this;

  static QueryClientProvider of(BuildContext context) {
    final QueryClientProvider? result =
        context.dependOnInheritedWidgetOfExactType<QueryClientProvider>();
    assert(result != null, 'QueryClientProvider not found');
    return result!;
  }
}

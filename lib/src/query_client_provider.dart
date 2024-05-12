import 'package:flutter/widgets.dart';
import 'query_client.dart';

/// This can be used to provide a [QueryClient] throughout the application.
class QueryClientProvider extends InheritedWidget {
  final QueryClient queryClient;
  const QueryClientProvider({
    super.key,
    required this.queryClient,
    required super.child,
  });

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => oldWidget != this;

  static QueryClientProvider of(BuildContext context) {
    final QueryClientProvider? result =
        context.dependOnInheritedWidgetOfExactType<QueryClientProvider>();
    assert(result != null, 'QueryClientProvider not found');
    return result!;
  }
}

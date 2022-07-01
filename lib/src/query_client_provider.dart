import 'package:flutter/widgets.dart';
import 'query_client.dart';

class QueryClientProvider extends InheritedWidget {
  final QueryClient queryClient;
  const QueryClientProvider({
    Key? key,
    required this.queryClient,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => oldWidget != this;

  static QueryClientProvider of(BuildContext context) {
    final QueryClientProvider? result =
        context.dependOnInheritedWidgetOfExactType<QueryClientProvider>();
    assert(result != null, 'QueryClientProvider not found');
    return result!;
  }
}

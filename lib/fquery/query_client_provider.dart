import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/main.dart';

class QueryClientProvider extends InheritedWidget {
  final QueryClient queryClient;
  const QueryClientProvider({
    Key? key,
    required this.queryClient,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static QueryClientProvider of(BuildContext context) {
    final QueryClientProvider? result =
        context.dependOnInheritedWidgetOfExactType<QueryClientProvider>();
    assert(result != null, 'QueryClientProvider not found');
    return result!;
  }
}

QueryClient useQueryClient() {
  return QueryClientProvider.of(useContext()).queryClient;
}

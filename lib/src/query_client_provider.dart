import 'package:flutter/widgets.dart';
import 'package:fquery/fquery.dart';

/// This can be used to provide a [QueryClient] throughout the application.
class QueryClientProvider extends InheritedWidget {
  final QueryClient queryClient;
  QueryClientProvider({
    super.key,
    required this.queryClient,
    required super.child,
  });

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => oldWidget != this;
}

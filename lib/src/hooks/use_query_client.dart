import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/src/query_client.dart';
import 'package:fquery/src/query_client_provider.dart';

/// Obtains the provided instance of [QueryClient]
/// from the nearest [QueryClientProvider] ancestor.
QueryClient useQueryClient() {
  final context = useContext();
  return QueryClient.of(context);
}

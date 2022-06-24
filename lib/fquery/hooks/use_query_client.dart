import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/query_client.dart';
import 'package:fquery/fquery/query_client_provider.dart';

QueryClient useQueryClient() {
  final context = useContext();
  return QueryClientProvider.of(context).queryClient;
}

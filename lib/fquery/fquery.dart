import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery/core/query_cache.dart';
import 'package:fquery/main.dart';

class UseQueryResult<T> {
  const UseQueryResult(
      {required this.data, required this.isLoading, required this.isIdle});

  final T data;
  final bool isLoading;
  final bool isIdle;
}

QueryCache useQueryCache() {
  final context = useContext();
  return QueryClientProvider.of(context).queryCache;
}

UseQueryResult<T> useQuery<T>(String queryKey, Future<T> Function() fetch) {
  final queryCache = useQueryCache();

  final data = useState<dynamic>(null);
  final isLoading = useState(queryOptions.isEnabled);
  final isIdle = useState(queryOptions.isEnabled ? false : true);

  useEffect(() {
    if (!queryOptions.isEnabled) {
      return;
    }

    fetch().then((value) {
      data.value = value;
      isLoading.value = false;
    });
  }, [queryKey, options]);

  return UseQueryResult(
    data: data.value,
    isLoading: isLoading.value,
    isIdle: isIdle.value,
  );
}

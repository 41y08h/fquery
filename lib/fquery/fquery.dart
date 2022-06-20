import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/main.dart';

class UseQueryOptions {
  final bool isEnabled;
  UseQueryOptions({this.isEnabled = true});
}

class UseQueryResult<T> {
  const UseQueryResult(
      {required this.data, required this.isLoading, required this.isIdle});

  final T data;
  final bool isLoading;
  final bool isIdle;
}

class Query<T> {
  final UseQueryOptions options;
  final Future<T> Function() queryFn;
  final String queryKey;
  final dynamic _data = null;
  final bool _isLoading = false;
  final bool _isIdle = true;

  get data => _data;
  get isLoading => _isLoading;
  get isIdle => _isIdle;

  Query({
    required this.options,
    required this.queryFn,
    required this.queryKey,
  });
}

UseQueryResult<T> useQuery<T>(
  String queryKey,
  Future<T> Function() fetch, {
  UseQueryOptions? options,
}) {
  final context = useContext();
  final queryCache = QueryCache.of(context);

  final queryOptions = options ?? UseQueryOptions();
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

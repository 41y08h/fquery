import 'package:fquery/fquery/core/types.dart';

class Query<TData extends dynamic, TError extends dynamic,
    TQueryKey extends QueryKey> {
  final Future<TData> Function() queryFn;
  final TQueryKey queryKey;
  final dynamic _data = null;
  final bool _isLoading = false;
  final bool _isIdle = true;

  get data => _data;
  get isLoading => _isLoading;
  get isIdle => _isIdle;

  Query({
    required this.queryFn,
    required this.queryKey,
  });
}

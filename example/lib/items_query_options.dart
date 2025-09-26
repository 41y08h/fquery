import 'package:basic/models/infinity.dart';
import 'package:fquery/fquery.dart';

final itemsQueryOptions = InfiniteQueryOptions<PageResult, Exception, int>(
  queryKey: QueryKey([
    'infinity',
    {'type': 'scroll'}
  ]),
  queryFn: (page) {
    final infinityAPI = Infinity.getInstance();
    return infinityAPI.get(page);
  },
  initialPageParam: 1,
  getNextPageParam: (lastPage, allPages, lastPageParam, allPageParam) {
    return lastPage.hasMore ? lastPage.page + 1 : null;
  },
  refetchOnMount: RefetchOnMount.never,
  cacheDuration: Duration(seconds: 5),
);

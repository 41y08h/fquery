import 'package:basic/models/infinity.dart';
import 'package:fquery/fquery.dart';

final itemsQueryConfig = InfiniteQueryOptions<PageResult, Exception, int>(
  queryKey: QueryKey([
    'infinity',
    {
      'type': 'scroll',
    },
  ]),
  queryFn: (page) {
    final infinityAPI = Infinity.getInstance();

    return infinityAPI.get(page);
  },
  initialPageParam: 1,
  getNextPageParam: (lastPage, allPages, lastPageParam, allPageParam) {
    return lastPage.hasMore ? lastPage.page + 1 : null;
  },
);

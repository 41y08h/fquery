import 'package:basic/models/infinity.dart';
import 'package:fquery/fquery.dart';

final itemsQueryConfig = InfiniteQueryConfig<PageResult, Exception, int>(
  queryKey: [
    'infinity',
    {
      'type': 'scroll',
    },
  ],
  queryFn: (page) {
    final infinityAPI = Infinity.getInstance();

    return infinityAPI.get(page);
  },
  initialPageParam: 1,
  getNextPageParam: (lastPage, allPages, lastPageParam, allPageParam) {
    return lastPage.hasMore ? lastPage.page + 1 : null;
  },
);

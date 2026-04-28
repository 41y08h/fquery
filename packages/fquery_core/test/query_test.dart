import 'package:test/test.dart';
import 'package:fquery_core/src/query.dart';

void main() {
  group('QueryKey', () {
    test('deep equality works', () {
      final k1 = QueryKey([
        'user',
        1,
        {'a': 1}
      ]);
      final k2 = QueryKey([
        'user',
        1,
        {'a': 1}
      ]);

      expect(k1, equals(k2));
      expect(k1.hashCode, equals(k2.hashCode));
    });

    test('serialized is stable json', () {
      final key = QueryKey(['a', 1, true]);
      expect(key.serialized, equals('["a",1,true]'));
    });

    test('toString contains serialized form', () {
      final key = QueryKey(['x']);
      expect(key.toString(), contains(key.serialized));
    });
  });

  group('FetchMeta', () {
    test('copyWith overrides direction', () {
      final meta = FetchMeta(direction: FetchDirection.forward);
      final next = meta.copyWith(direction: FetchDirection.backward);

      expect(next.direction, FetchDirection.backward);
    });

    test('copyWith keeps old value when null', () {
      final meta = FetchMeta(direction: FetchDirection.forward);
      final next = meta.copyWith();

      expect(next.direction, FetchDirection.forward);
    });
  });

  group('InfiniteQueryData', () {
    test('copyWith updates fields correctly', () {
      final data = InfiniteQueryData<int, int>(
        pages: [1, 2],
        pageParams: [10, 20],
      );

      final next = data.copyWith(pages: [3]);

      expect(next.pages, [3]);
      expect(next.pageParams, [10, 20]); // unchanged
    });
  });

  group('Query computed getters', () {
    final key = QueryKey(['k']);

    test('isLoading when status loading', () {
      final q = Query(key, status: QueryStatus.loading);
      expect(q.isLoading, true);
      expect(q.isSuccess, false);
      expect(q.isError, false);
    });

    test('isSuccess when status success', () {
      final q = Query(key, status: QueryStatus.success);
      expect(q.isSuccess, true);
      expect(q.isLoading, false);
      expect(q.isError, false);
    });

    test('isError when status error', () {
      final q = Query(key, status: QueryStatus.error);
      expect(q.isError, true);
      expect(q.isLoading, false);
      expect(q.isSuccess, false);
    });
  });

  group('QueryOptions', () {
    test('constructs correctly', () {
      final options = QueryOptions<int, Exception>(
        queryKey: QueryKey(['test']),
        queryFn: () => 42,
      );

      expect(options.queryFn(), 42);
      expect(options.queryKey.raw, ['test']);
    });
  });

  group('InfiniteQueryOptions', () {
    test('constructs correctly', () {
      final options = InfiniteQueryOptions<int, Exception, int>(
        queryKey: QueryKey(['inf']),
        queryFn: (page) => page * 2,
        initialPageParam: 1,
        getNextPageParam: (last, pages, lastParam, params) => lastParam + 1,
      );

      expect(options.queryFn(2), 4);
      expect(options.initialPageParam, 1);
      expect(options.getNextPageParam(1, [1], 1, [1]), 2);
    });
  });

  group('QueryResult', () {
    test('constructs correctly', () {
      final result = QueryResult<int, Exception>(
        data: 5,
        dataUpdatedAt: DateTime.now(),
        error: null,
        errorUpdatedAt: null,
        isError: false,
        isLoading: false,
        isFetching: false,
        isSuccess: true,
        status: QueryStatus.success,
        refetch: () {},
        isInvalidated: false,
        isRefetchError: false,
      );

      expect(result.data, 5);
      expect(result.isSuccess, true);
      expect(result.status, QueryStatus.success);
    });
  });

  group('InfiniteQueryResult', () {
    test('constructs correctly', () {
      final result = InfiniteQueryResult<int, Exception, int>(
        data: InfiniteQueryData(pages: [1], pageParams: [0]),
        dataUpdatedAt: DateTime.now(),
        error: null,
        errorUpdatedAt: null,
        isError: false,
        isLoading: false,
        isFetching: false,
        isSuccess: true,
        status: QueryStatus.success,
        refetch: () {},
        isInvalidated: false,
        isFetchingNextPage: false,
        isFetchingPreviousPage: false,
        fetchNextPage: () {},
        fetchPreviousPage: () {},
        hasNextPage: true,
        hasPreviousPage: false,
        isRefetching: false,
        isFetchNextPageError: false,
        isFetchPreviousPageError: false,
        isRefetchError: false,
      );

      expect(result.data?.pages, [1]);
      expect(result.hasNextPage, true);
      expect(result.hasPreviousPage, false);
    });
  });
}

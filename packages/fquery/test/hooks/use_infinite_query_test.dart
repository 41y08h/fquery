import 'package:flutter_test/flutter_test.dart';
import 'package:fquery_core/fquery_core.dart';

void main() {
  group('InfiniteQueryObserver - updateOptions', () {
    test('should reflect enabled changes when updateOptions is called', () {
      final queryCache = QueryCache(
        defaultQueryOptions: DefaultQueryOptions(
          cacheDuration: Duration.zero,
        ),
      );

      final observer = InfiniteQueryObserver<String, Exception, int>(
        cache: queryCache,
        queryKey: QueryKey(['infinite-test']),
        queryFn: (page) => 'page-$page',
        enabled: true,
        initialPageParam: 1,
        getNextPageParam: (lastPage, allPages, lastPageParam, allPageParams) {
          return lastPageParam + 1;
        },
      );

      // Initial state: enabled = true
      expect(observer.enabled, isTrue);

      // Update enabled to false
      observer.updateOptions(InfiniteQueryOptions(
        queryKey: QueryKey(['infinite-test']),
        queryFn: (page) => 'page-$page',
        enabled: false,
        initialPageParam: 1,
        getNextPageParam: (lastPage, allPages, lastPageParam, allPageParams) {
          return lastPageParam + 1;
        },
      ));

      expect(observer.enabled, isFalse);

      observer.updateOptions(InfiniteQueryOptions(
        queryKey: QueryKey(['infinite-test']),
        queryFn: (page) => 'page-$page',
        enabled: true,
        initialPageParam: 1,
        getNextPageParam: (lastPage, allPages, lastPageParam, allPageParams) {
          return lastPageParam + 1;
        },
      ));

      expect(observer.enabled, isTrue);
      observer.dispose();
    });

    test('should cancel fetch when enabled changes from true to false', () async {
      final queryCache = QueryCache(
        defaultQueryOptions: DefaultQueryOptions(
          cacheDuration: Duration.zero,
        ),
      );

      final observer = InfiniteQueryObserver<String, Exception, int>(
        cache: queryCache,
        queryKey: QueryKey(['infinite-test-cancel']),
        queryFn: (page) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 'page-$page';
        },
        enabled: true,
        initialPageParam: 1,
        getNextPageParam: (lastPage, allPages, lastPageParam, allPageParams) {
          return lastPageParam + 1;
        },
      );

      // Update enabled to false to cancel fetch
      observer.updateOptions(InfiniteQueryOptions(
        queryKey: QueryKey(['infinite-test-cancel']),
        queryFn: (page) => 'page-$page',
        enabled: false,
        initialPageParam: 1,
        getNextPageParam: (lastPage, allPages, lastPageParam, allPageParams) {
          return lastPageParam + 1;
        },
      ));

      await observer.fetch();
      expect(observer.query.isFetching, isFalse);
      observer.dispose();
    });

    test('should update state correctly when enabled changes from false to true', () async {
      final queryCache = QueryCache(
        defaultQueryOptions: DefaultQueryOptions(
          cacheDuration: Duration.zero,
        ),
      );

      final observer = InfiniteQueryObserver<String, Exception, int>(
        cache: queryCache,
        queryKey: QueryKey(['infinite-test-enable']),
        queryFn: (page) => 'page-$page',
        enabled: false, // Initially disabled
        initialPageParam: 1,
        getNextPageParam: (lastPage, allPages, lastPageParam, allPageParams) {
          return lastPageParam + 1;
        },
      );

      // Initial state: enabled = false
      expect(observer.enabled, isFalse);

      // Update enabled to true
      observer.updateOptions(InfiniteQueryOptions(
        queryKey: QueryKey(['infinite-test-enable']),
        queryFn: (page) => 'page-$page',
        enabled: true,
        initialPageParam: 1,
        getNextPageParam: (lastPage, allPages, lastPageParam, allPageParams) {
          return lastPageParam + 1;
        },
      ));

      expect(observer.enabled, isTrue);
      observer.dispose();
    });
  });
}

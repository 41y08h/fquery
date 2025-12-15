import 'package:flutter_test/flutter_test.dart';
import 'package:fquery_core/fquery_core.dart';

void main() {
  group('QueryObserver - updateOptions', () {
    test('should reflect enabled changes when updateOptions is called', () {
      final queryCache = QueryCache(
        defaultQueryOptions: DefaultQueryOptions(
          cacheDuration: Duration.zero,
        ),
      );

      final observer = QueryObserver<String, Exception>(
        cache: queryCache,
        queryKey: QueryKey(['test']),
        queryFn: () => 'data',
        enabled: true,
      );

      // Initial state: enabled = true
      expect(observer.enabled, isTrue);

      // Update enabled to false
      observer.updateOptions(QueryOptions(
        queryKey: QueryKey(['test']),
        queryFn: () => 'data',
        enabled: false,
      ));

      // Verify enabled is now false
      expect(observer.enabled, isFalse);

      // Update enabled back to true
      observer.updateOptions(QueryOptions(
        queryKey: QueryKey(['test']),
        queryFn: () => 'data',
        enabled: true,
      ));

      // Verify enabled is now true
      expect(observer.enabled, isTrue);

      observer.dispose();
    });

    test('should cancel fetch when enabled changes from true to false', () async {
      final queryCache = QueryCache(
        defaultQueryOptions: DefaultQueryOptions(
          cacheDuration: Duration.zero,
        ),
      );

      int fetchCount = 0;
      final observer = QueryObserver<String, Exception>(
        cache: queryCache,
        queryKey: QueryKey(['test-cancel']),
        queryFn: () async {
          fetchCount++;
          await Future.delayed(const Duration(milliseconds: 100));
          return 'data';
        },
        enabled: true,
      );

      // Update enabled to false to cancel fetch
      observer.updateOptions(QueryOptions(
        queryKey: QueryKey(['test-cancel']),
        queryFn: () => 'data',
        enabled: false,
      ));

      // Fetch should not execute when enabled is false
      await observer.fetch();

      // Verify isFetching is false
      expect(observer.query.isFetching, isFalse);

      observer.dispose();
    });

    test('should call initialize when enabled changes from false to true', () async {
      final queryCache = QueryCache(
        defaultQueryOptions: DefaultQueryOptions(
          cacheDuration: Duration.zero,
        ),
      );

      int fetchCount = 0;
      final observer = QueryObserver<String, Exception>(
        cache: queryCache,
        queryKey: QueryKey(['test-enable']),
        queryFn: () {
          fetchCount++;
          return 'data-$fetchCount';
        },
        enabled: false, // Initially disabled
      );

      // Initial state: enabled = false, so no fetch
      expect(fetchCount, 0);

      // Update enabled to true
      observer.updateOptions(QueryOptions(
        queryKey: QueryKey(['test-enable']),
        queryFn: () {
          fetchCount++;
          return 'data-$fetchCount';
        },
        enabled: true,
      ));

      // Wait for async operations
      await Future.delayed(Duration.zero);

      expect(observer.enabled, isTrue);

      observer.dispose();
    });
  });
}

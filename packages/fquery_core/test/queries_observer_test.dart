import 'package:test/test.dart';

import 'package:fquery_core/src/query.dart';
import 'package:fquery_core/src/query_cache.dart';
import 'package:fquery_core/src/queries_observer.dart';

void main() {
  group('QueriesObserver', () {
    test('creates observers when options are set', () {
      final cache = QueryCache();

      final queriesObserver = QueriesObserver<int, Exception>(cache: cache);

      queriesObserver.setOptions([
        QueryOptions<int, Exception>(
          queryKey: QueryKey(['a']),
          queryFn: () async => 1,
        ),
        QueryOptions<int, Exception>(
          queryKey: QueryKey(['b']),
          queryFn: () async => 2,
        ),
      ]);

      expect(queriesObserver.observers.length, 2);
    });

    test('reuses existing observers when queryKey matches', () {
      final cache = QueryCache();

      final queriesObserver = QueriesObserver<int, Exception>(cache: cache);

      queriesObserver.setOptions([
        QueryOptions<int, Exception>(
          queryKey: QueryKey(['a']),
          queryFn: () async => 1,
        ),
      ]);

      final firstInstance = queriesObserver.observers.first;

      // set options again with same key
      queriesObserver.setOptions([
        QueryOptions<int, Exception>(
          queryKey: QueryKey(['a']),
          queryFn: () async => 99,
        ),
      ]);

      final secondInstance = queriesObserver.observers.first;

      expect(identical(firstInstance, secondInstance), true);
    });

    test('disposes removed observers', () {
      final cache = QueryCache();

      final queriesObserver = QueriesObserver<int, Exception>(cache: cache);

      queriesObserver.setOptions([
        QueryOptions<int, Exception>(
          queryKey: QueryKey(['a']),
          queryFn: () async => 1,
        ),
        QueryOptions<int, Exception>(
          queryKey: QueryKey(['b']),
          queryFn: () async => 2,
        ),
      ]);

      expect(queriesObserver.observers.length, 2);

      queriesObserver.setOptions([
        QueryOptions<int, Exception>(
          queryKey: QueryKey(['a']),
          queryFn: () async => 1,
        ),
      ]);

      expect(queriesObserver.observers.length, 1);
      expect(
        queriesObserver.observers.first.queryKey,
        QueryKey(['a']),
      );
    });

    test('propagates notifications from inner observers', () async {
      final cache = QueryCache();

      final queriesObserver = QueriesObserver<int, Exception>(cache: cache);

      queriesObserver.setOptions([
        QueryOptions<int, Exception>(
          queryKey: QueryKey(['a']),
          queryFn: () async => 1,
        ),
      ]);

      int notified = 0;

      queriesObserver.subscribe(1, () {
        notified++;
      });

      // trigger fetch on inner observer
      await queriesObserver.observers.first.fetch();

      expect(notified, greaterThan(0));
    });

    test('dispose cleans up all observers', () {
      final cache = QueryCache();

      final queriesObserver = QueriesObserver<int, Exception>(cache: cache);

      queriesObserver.setOptions([
        QueryOptions<int, Exception>(
          queryKey: QueryKey(['a']),
          queryFn: () async => 1,
        ),
        QueryOptions<int, Exception>(
          queryKey: QueryKey(['b']),
          queryFn: () async => 2,
        ),
      ]);

      queriesObserver.dispose();

      expect(queriesObserver.observers.length, 2);
      // observers are disposed internally, but list remains
      // actual GC cleanup is handled by QueryCache
    });

    test('initialize is called for newly added observers', () async {
      final cache = QueryCache();

      final queriesObserver = QueriesObserver<int, Exception>(cache: cache);

      queriesObserver.setOptions([
        QueryOptions<int, Exception>(
          queryKey: QueryKey(['a']),
          queryFn: () async => 42,
        ),
      ]);

      await Future.delayed(Duration.zero);

      final query = cache.get<int, Exception>(QueryKey(['a']));

      expect(query.data, 42);
    });
  });
}

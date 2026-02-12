import 'package:test/test.dart';
import 'package:fake_async/fake_async.dart';

import 'package:fquery_core/src/query_cache.dart';
import 'package:fquery_core/src/query.dart';
import 'package:fquery_core/src/observer.dart';

void main() {
  group('QueryCache - build & get', () {
    test('build creates a query and get returns it', () {
      final cache = QueryCache();

      final query = cache.build<int, Exception>(
        queryKey: QueryKey(['counter']),
      );

      final fetched = cache.get<int, Exception>(QueryKey(['counter']));

      expect(fetched, same(query));
    });

    test('get throws if query not found', () {
      final cache = QueryCache();

      expect(
        () => cache.get<int, Exception>(QueryKey(['missing'])),
        throwsA(isA<QueryNotFoundException>()),
      );
    });
  });

  group('dispatch success', () {
    test('sets data and status to success', () {
      final cache = QueryCache();

      final key = QueryKey(['todos']);

      cache.build<List<String>, Exception>(queryKey: key);

      cache.dispatch<List<String>, Exception>(
        key,
        DispatchAction.success,
        ['a', 'b'],
      );

      final query = cache.get<List<String>, Exception>(key);

      expect(query.status, QueryStatus.success);
      expect(query.data, ['a', 'b']);
      expect(query.isFetching, false);
    });
  });

  group('dispatch fetch', () {
    test('sets isFetching true and status loading if no data', () {
      final cache = QueryCache();
      final key = QueryKey(['user']);

      cache.build<int, Exception>(queryKey: key);

      cache.dispatch<int, Exception>(
        key,
        DispatchAction.fetch,
        null,
      );

      final query = cache.get<int, Exception>(key);

      expect(query.isFetching, true);
      expect(query.status, QueryStatus.loading);
    });
  });

  group('setQueryData', () {
    test('creates query if missing and sets data', () {
      final cache = QueryCache();

      cache.setQueryData<int, Exception>(
        ['count'],
        (prev) => (prev ?? 0) + 1,
      );

      final value = cache.getQueryData<int, Exception>(['count']);

      expect(value, 1);
    });

    test('updates existing data', () {
      final cache = QueryCache();

      cache.setQueryData<int, Exception>(['count'], (_) => 5);
      cache.setQueryData<int, Exception>(['count'], (prev) => prev! + 2);

      final value = cache.getQueryData<int, Exception>(['count']);

      expect(value, 7);
    });
  });

  group('invalidateQueries', () {
    test('invalidates matching queries', () {
      final cache = QueryCache();

      final key = QueryKey(['posts']);

      cache.build<List<int>, Exception>(queryKey: key);

      cache.dispatch<List<int>, Exception>(
        key,
        DispatchAction.success,
        [1, 2],
      );

      cache.invalidateQueries<List<int>, Exception>(['posts']);

      final query = cache.get<List<int>, Exception>(key);

      expect(query.isInvalidated, true);
    });
  });

  group('removeQueries', () {
    test('removes matching queries', () {
      final cache = QueryCache();

      final key = QueryKey(['posts']);

      cache.build<List<int>, Exception>(queryKey: key);

      cache.removeQueries<List<int>, Exception>(['posts']);

      expect(
        () => cache.get<List<int>, Exception>(key),
        throwsA(isA<QueryNotFoundException>()),
      );
    });
  });

  group('isFetching', () {
    test('counts fetching queries', () {
      final cache = QueryCache();

      final key1 = QueryKey(['a']);
      final key2 = QueryKey(['b']);

      cache.build<int, Exception>(queryKey: key1);
      cache.build<int, Exception>(queryKey: key2);

      cache.dispatch<int, Exception>(key1, DispatchAction.fetch, null);

      expect(cache.isFetching, 1);
    });
  });

  group('garbage collection', () {
    test('removes query after cacheDuration when no observers', () {
      fakeAsync((async) {
        final cache = QueryCache();

        final key = QueryKey(['temp']);

        // create initial query
        cache.build<int, Exception>(queryKey: key);

        // create a concrete observer instead of abstract Observer
        final observer = QueryObserver<int, Exception>(
          cache: cache,
          queryKey: key,
          queryFn: () async => 1,
          cacheDuration: const Duration(seconds: 5),
        );

        // attach observer to cache
        cache.build<int, Exception>(queryKey: key, observer: observer);

        // simulate dispose (this triggers dismantle internally)
        observer.dispose();

        // fast-forward time
        async.elapse(const Duration(seconds: 2));

        expect(() => cache.get<int, Exception>(key), returnsNormally);

        async.elapse(const Duration(seconds: 3));

        expect(
          () => cache.get<int, Exception>(key),
          throwsA(isA<QueryNotFoundException>()),
        );
      });
    });
  });
}

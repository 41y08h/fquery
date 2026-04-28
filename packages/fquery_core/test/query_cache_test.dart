import 'package:test/test.dart';
import 'package:fake_async/fake_async.dart';

import 'package:fquery_core/src/query_cache.dart';
import 'package:fquery_core/src/query.dart';
import 'package:fquery_core/src/observer.dart';

void main() {
  group('QueryCache - build & get', () {
    test('build creates a query and get returns it', () {
      final cache = QueryCache();

      final key = QueryKey<int, Exception>(['counter']);

      final query = cache.build(queryKey: key);

      final fetched = cache.get(key);

      expect(fetched, same(query));
    });

    test('get throws if query not found', () {
      final cache = QueryCache();

      final key = QueryKey<int, Exception>(['missing']);

      expect(
        () => cache.get(key),
        throwsA(isA<QueryNotFoundException>()),
      );
    });
  });

  group('dispatch success', () {
    test('sets data and status to success', () {
      final cache = QueryCache();

      final key = QueryKey<List<String>, Exception>(['todos']);

      cache.build(queryKey: key);

      cache.dispatch(
        key,
        DispatchAction.success,
        ['a', 'b'],
      );

      final query = cache.get(key);

      expect(query.status, QueryStatus.success);
      expect(query.data, ['a', 'b']);
      expect(query.isFetching, false);
    });
  });

  group('dispatch fetch', () {
    test('sets isFetching true and status loading if no data', () {
      final cache = QueryCache();

      final key = QueryKey<int, Exception>(['user']);

      cache.build(queryKey: key);

      cache.dispatch(
        key,
        DispatchAction.fetch,
        null,
      );

      final query = cache.get(key);

      expect(query.isFetching, true);
      expect(query.status, QueryStatus.loading);
    });
  });

  group('setQueryData', () {
    test('creates query if missing and sets data', () {
      final cache = QueryCache();

      final key = QueryKey<int, Exception>(['count']);

      cache.setQueryData<int, Exception>(
        key.raw,
        (prev) => (prev ?? 0) + 1,
      );

      final value = cache.getQueryData(key.raw);

      expect(value, 1);
    });

    test('updates existing data', () {
      final cache = QueryCache();

      final key = QueryKey<int, Exception>(['count']);

      cache.setQueryData<int, Exception>(key.raw, (_) => 5);
      cache.setQueryData<int, Exception>(key.raw, (prev) => prev! + 2);

      final value = cache.getQueryData(key.raw);

      expect(value, 7);
    });
  });

  group('invalidateQueries', () {
    test('invalidates matching queries', () {
      final cache = QueryCache();

      final key = QueryKey<List<int>, Exception>(['posts']);

      cache.build(queryKey: key);

      cache.dispatch(
        key,
        DispatchAction.success,
        [1, 2],
      );

      cache.invalidateQueries(key.raw);

      final query = cache.get(key);

      expect(query.isInvalidated, true);
    });
  });

  group('removeQueries', () {
    test('removes matching queries', () {
      final cache = QueryCache();

      final key = QueryKey<List<int>, Exception>(['posts']);

      cache.build(queryKey: key);

      cache.removeQueries(key.raw);

      expect(
        () => cache.get(key),
        throwsA(isA<QueryNotFoundException>()),
      );
    });
  });

  group('isFetching', () {
    test('counts fetching queries', () {
      final cache = QueryCache();

      final key1 = QueryKey<int, Exception>(['a']);
      final key2 = QueryKey<int, Exception>(['b']);

      cache.build(queryKey: key1);
      cache.build(queryKey: key2);

      cache.dispatch(key1, DispatchAction.fetch, null);

      expect(cache.isFetching, 1);
    });
  });

  group('garbage collection', () {
    test('removes query after cacheDuration when no observers', () {
      fakeAsync((async) {
        final cache = QueryCache();

        final key = QueryKey<int, Exception>(['temp']);

        // create initial query
        cache.build(queryKey: key);

        final observer = QueryObserver(
          cache: cache,
          queryKey: key,
          queryFn: () async => 1,
          cacheDuration: const Duration(seconds: 5),
        );

        // attach observer to cache
        cache.build(queryKey: key, observer: observer);

        // simulate dispose
        observer.dispose();

        async.elapse(const Duration(seconds: 2));

        expect(() => cache.get(key), returnsNormally);

        async.elapse(const Duration(seconds: 3));
        expect(
          () => cache.get(key),
          throwsA(isA<QueryNotFoundException>()),
        );
      });
    });
  });
}

import 'dart:async';
import 'package:test/test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:fquery_core/fquery_core.dart';

void main() async {
  test('GC uses the longest cache duration of the lifetime', () {
    fakeAsync((async) {
      final cache = QueryCache();

      final firstObs = QueryObserver(
        cache: cache,
        queryKey: QueryKey(['gc']),
        queryFn: () {
          return 1;
        },
        cacheDuration: Duration(milliseconds: 10),
      );

      final secondObs = QueryObserver(
        cache: cache,
        queryKey: QueryKey(['gc']),
        queryFn: () {
          return 2;
        },
        cacheDuration: Duration(milliseconds: 30),
      );

      cache.dismantle(secondObs);
      cache.dismantle(firstObs);

      async.elapse(Duration(milliseconds: 20));
      expect(cache.queries, isNotEmpty);

      async.elapse(Duration(milliseconds: 20));
      expect(cache.queries, isEmpty);
    });
  });

  test('Notifications are scoped', () {
    fakeAsync((async) {
      final cache = QueryCache();
      var count = 0;

      final o1 = QueryObserver(
          cache: cache, queryKey: QueryKey(['q1']), queryFn: () => 1);

      final o2 = QueryObserver(
          cache: cache, queryKey: QueryKey(['q2']), queryFn: () => 2);

      o1.subscribe(1, () {
        count++;
      });

      o2.subscribe(1, () {
        count++;
      });

      o1.initialize();
      async.elapse(Duration(milliseconds: 10));

      // 1+1 because of `fetch` and `success` notifications from o1
      expect(count, equals(2));
    });
  });

  group('Query states are sane', () {
    test('Query initial state is sane', () {
      final cache = QueryCache();

      final o1 = QueryObserver(
          cache: cache, queryKey: QueryKey(['q1']), queryFn: () => 1);

      expect(o1.query.isFetching, isFalse);
      expect(o1.query.data, isNull);
      expect(o1.query.error, isNull);
      expect(o1.query.status, equals(QueryStatus.loading));
      expect(o1.query.dataUpdatedAt, isNull);
      expect(o1.query.errorUpdatedAt, isNull);
      expect(o1.query.fetchMeta, isNull);
      expect(o1.query.isInvalidated, isFalse);
      expect(o1.query.isRefetchError, isFalse);
    });

    test('Query fetch state is sane', () {
      final cache = QueryCache();

      final o1 = QueryObserver(
          cache: cache, queryKey: QueryKey(['q1']), queryFn: () => 1);

      o1.initialize();

      expect(o1.query.isFetching, isTrue);
      expect(o1.query.data, isNull);
      expect(o1.query.error, isNull);
      expect(o1.query.status, equals(QueryStatus.loading));
      expect(o1.query.dataUpdatedAt, isNull);
      expect(o1.query.errorUpdatedAt, isNull);
      expect(o1.query.fetchMeta, isNull);
      expect(o1.query.isInvalidated, isFalse);
      expect(o1.query.isRefetchError, isFalse);
    });

    test('Query success state is sane', () {
      fakeAsync((async) async {
        final cache = QueryCache();

        final o1 = QueryObserver(
            cache: cache,
            queryKey: QueryKey(['q1']),
            queryFn: () async {
              return 1;
            });

        final initialTimestamp = DateTime.now();
        o1.initialize();

        async.flushMicrotasks();
        await Future.delayed(Duration(milliseconds: 10));

        expect(o1.query.isFetching, isFalse);
        expect(o1.query.data, isNotNull);
        expect(o1.query.error, isNull);
        expect(o1.query.status, equals(QueryStatus.success));
        expect(initialTimestamp.isBefore(o1.query.dataUpdatedAt!), isTrue);
        expect(o1.query.errorUpdatedAt, isNull);
        expect(o1.query.fetchMeta, isNull);
        expect(o1.query.isInvalidated, isFalse);
        expect(o1.query.isRefetchError, isFalse);
      });
    });

    test('Query error state is sane', () {
      fakeAsync((async) async {
        final cache = QueryCache();

        final o1 = QueryObserver(
            cache: cache,
            queryKey: QueryKey(['q1']),
            retryCount: 0,
            queryFn: () {
              throw Exception('error');
            });

        final initialTimestamp = DateTime.now();
        o1.initialize();

        async.flushMicrotasks();
        // will fix and use fake clock after having injectible clock in the library itself
        await Future.delayed(Duration(milliseconds: 10));

        expect(o1.query.isFetching, isFalse);
        expect(o1.query.data, isNull);
        expect(o1.query.error, isNotNull);
        expect(o1.query.status, equals(QueryStatus.error));
        expect(o1.query.dataUpdatedAt, isNull);
        expect(initialTimestamp.isBefore(o1.query.errorUpdatedAt!), isTrue);
        expect(o1.query.fetchMeta, isNull);
        expect(o1.query.isInvalidated, isFalse);
        expect(o1.query.isRefetchError, isFalse);
      });
    });
  });

  group(
      'Query configuration options are respected and produces effects as expected',
      () {
    test('Retries before giving up', () {
      fakeAsync((async) {
        final cache = QueryCache();

        var count = 0;
        final o1 = QueryObserver(
            cache: cache,
            queryKey: QueryKey(['q1']),
            retryCount: 3,
            retryDelay: Duration.zero,
            queryFn: () {
              count++;
              throw Exception('error');
            });

        o1.initialize();
        async.elapse(Duration(milliseconds: 500));

        expect(count, equals(4));
      });
    });

    test('Retries can be turned off', () {
      fakeAsync((async) {
        final cache = QueryCache();

        var count = 0;
        final o1 = QueryObserver(
            cache: cache,
            queryKey: QueryKey(['q1']),
            retryCount: 0,
            retryDelay: Duration.zero,
            queryFn: () {
              count++;
              throw Exception('error');
            });

        o1.initialize();
        async.elapse(Duration(milliseconds: 500));

        expect(count, equals(1));
      });
    });

    test('Retry delay is respected', () {
      fakeAsync((async) {
        final cache = QueryCache();

        var count = 0;
        final o1 = QueryObserver(
            cache: cache,
            queryKey: QueryKey(['q1']),
            retryCount: 3,
            retryDelay: Duration(milliseconds: 100),
            queryFn: () {
              count++;
              throw Exception('error');
            });

        o1.initialize();
        async.elapse(Duration(milliseconds: 50));

        expect(count, equals(1));

        async.elapse(Duration(milliseconds: 100));
        expect(count, equals(2));
      });
    });

    test('Enable/disable side effects work', () {
      fakeAsync((async) {
        final cache = QueryCache();

        var count = 0;
        final o1 = QueryObserver(
            cache: cache,
            queryKey: QueryKey(['q1']),
            enabled: false,
            queryFn: () {
              count++;
              return 1;
            });

        o1.initialize();
        async.elapse(Duration(milliseconds: 50));

        expect(count, equals(0));

        o1.updateOptions(
          QueryOptions(
              enabled: true, queryKey: o1.queryKey, queryFn: o1.queryFn),
        );

        async.elapse(Duration(milliseconds: 50));
        expect(count, equals(1));
      });
    });

    test('Refetches in specified intervals', () {
      fakeAsync((async) {
        final cache = QueryCache();

        var count = 0;
        final o1 = QueryObserver(
            cache: cache,
            queryKey: QueryKey(['q1']),
            refetchInterval: Duration(milliseconds: 20),
            queryFn: () {
              count++;
              return 1;
            });

        o1.initialize();
        async.elapse(Duration(milliseconds: 50));

        expect(count, greaterThan(1));
      });
    });

    test('Refetch interval changes are respected', () {
      fakeAsync((async) {
        final cache = QueryCache();

        var count = 0;
        final o1 = QueryObserver(
            cache: cache,
            queryKey: QueryKey(['q1']),
            refetchInterval: Duration(milliseconds: 100),
            queryFn: () {
              count++;
              return 1;
            });

        o1.initialize();
        async.elapse(Duration(milliseconds: 50));

        expect(count, equals(1));

        o1.updateOptions(
          QueryOptions(
              refetchInterval: Duration(milliseconds: 10),
              queryKey: o1.queryKey,
              queryFn: o1.queryFn),
        );

        async.elapse(Duration(milliseconds: 50));
        expect(count, greaterThan(2));
      });
    });

    test('Query is refetched when invalidated', () {
      fakeAsync((async) {
        final cache = QueryCache();

        var count = 0;
        final o1 = QueryObserver(
            cache: cache,
            queryKey: QueryKey(['q1']),
            queryFn: () {
              count++;
              return 1;
            });

        o1.initialize();
        async.elapse(Duration(milliseconds: 50));

        expect(count, equals(1));

        cache.invalidateQueries(['q1']);

        async.elapse(Duration(milliseconds: 50));
        expect(count, equals(2));
      });
    });

    test('Refetch on mount works', () {
      fakeAsync((async) async {
        final cache = QueryCache();

        var count = 0;
        final o1 = QueryObserver(
            cache: cache,
            queryKey: QueryKey(['q1']),
            refetchOnMount: RefetchOnMount.always,
            queryFn: () {
              count++;
              return 1;
            });

        o1.initialize();
        async.elapse(Duration(milliseconds: 50));
        o1.initialize();

        expect(count, equals(2));

        o1.updateOptions(
          QueryOptions(
              refetchOnMount: RefetchOnMount.never,
              queryKey: o1.queryKey,
              queryFn: o1.queryFn),
        );

        o1.initialize();

        expect(count, equals(2));

        o1.updateOptions(
          QueryOptions(
            staleDuration: Duration(milliseconds: 50),
            refetchOnMount: RefetchOnMount.stale,
            queryKey: o1.queryKey,
            queryFn: o1.queryFn,
          ),
        );

        o1.initialize();

        await Future.delayed(Duration(milliseconds: 100));
        expect(count, equals(3));
      });
    });
  });
}

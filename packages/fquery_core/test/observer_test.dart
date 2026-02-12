import 'dart:async';

import 'package:test/test.dart';
import 'package:fake_async/fake_async.dart';

import 'package:fquery_core/src/query_cache.dart';
import 'package:fquery_core/src/query.dart';
import 'package:fquery_core/src/observer.dart';

void main() {
  group('Observable mixin', () {
    test('subscribe and notify works', () {
      final obs = _TestObservable();

      int count = 0;

      obs.subscribe(1, () => count++);
      obs.notifyObservers();

      expect(count, 1);
    });

    test('unsubscribe stops notifications', () {
      final obs = _TestObservable();

      int count = 0;

      obs.subscribe(1, () => count++);
      obs.unsubscribe(1);

      obs.notifyObservers();

      expect(count, 0);
    });
  });

  group('QueryObserver - fetch lifecycle', () {
    test('fetch success updates cache', () async {
      final cache = QueryCache();

      final observer = QueryObserver<int, Exception>(
        cache: cache,
        queryKey: QueryKey(['a']),
        queryFn: () async => 42,
      );

      await observer.fetch();

      final query = cache.get<int, Exception>(QueryKey(['a']));

      expect(query.data, 42);
      expect(query.status, QueryStatus.success);
      expect(query.isFetching, false);
    });

    test('fetch error updates cache', () async {
      final cache = QueryCache();

      final observer = QueryObserver<int, Exception>(
        cache: cache,
        queryKey: QueryKey(['a']),
        queryFn: () async => throw Exception('fail'),
        retryCount: 0,
      );

      await observer.fetch();

      final query = cache.get<int, Exception>(QueryKey(['a']));

      expect(query.status, QueryStatus.error);
      expect(query.error, isA<Exception>());
    });
  });

  group('QueryObserver - initialize behavior', () {
    test('initialize triggers fetch when no data', () async {
      final cache = QueryCache();

      final observer = QueryObserver<int, Exception>(
        cache: cache,
        queryKey: QueryKey(['init']),
        queryFn: () async {
          return 10;
        },
      );

      observer.initialize();

      await Future.delayed(Duration.zero);

      final query = cache.get<int, Exception>(QueryKey(['init']));
      expect(query.data, 10);
    });

    test('initialize respects enabled = false', () async {
      final cache = QueryCache();

      final observer = QueryObserver<int, Exception>(
        cache: cache,
        queryKey: QueryKey(['init']),
        queryFn: () async => 10,
        enabled: false,
      );

      observer.initialize();

      final query = cache.get<int, Exception>(QueryKey(['init']));
      expect(query.data, null);
    });
  });

  group('QueryObserver - invalidation triggers refetch', () {
    test('invalidated query refetches automatically', () async {
      final cache = QueryCache();

      int counter = 0;

      final observer = QueryObserver<int, Exception>(
        cache: cache,
        queryKey: QueryKey(['inv']),
        queryFn: () async => ++counter,
      );

      await observer.fetch();

      cache.invalidateQueries<int, Exception>(['inv']);

      await Future.delayed(Duration.zero);

      final query = cache.get<int, Exception>(QueryKey(['inv']));

      expect(query.data, 2);
    });
  });

  group('QueryObserver - refetchInterval', () {
    test('schedules refetch repeatedly', () {
      fakeAsync((async) {
        final cache = QueryCache();

        int counter = 0;

        final observer = QueryObserver<int, Exception>(
          cache: cache,
          queryKey: QueryKey(['interval']),
          queryFn: () async => ++counter,
          refetchInterval: Duration(seconds: 5),
        );

        observer.fetch();

        async.elapse(Duration(seconds: 5));
        async.flushMicrotasks();

        async.elapse(Duration(seconds: 5));
        async.flushMicrotasks();

        final query = cache.get<int, Exception>(QueryKey(['interval']));

        expect(query.data, 3); // initial + 2 refetches
      });
    });
  });

  group('Observer notification propagation', () {
    test('observer notifies its subscribers when cache updates', () async {
      final cache = QueryCache();

      final observer = QueryObserver<int, Exception>(
        cache: cache,
        queryKey: QueryKey(['notify']),
        queryFn: () async => 1,
      );

      int notified = 0;

      observer.subscribe(1, () {
        notified++;
      });

      await observer.fetch();

      expect(notified, greaterThan(0));
    });
  });

  // ---------------- Infinite Query ----------------

  group('InfiniteQueryObserver', () {
    test('initial fetch creates first page', () async {
      final cache = QueryCache();

      final observer = InfiniteQueryObserver<int, Exception, int>(
        cache: cache,
        queryKey: QueryKey(['inf']),
        queryFn: (page) async => page,
        initialPageParam: 1,
        getNextPageParam: (last, pages, lastParam, params) => lastParam + 1,
      );

      await observer.fetch();

      final query =
          cache.get<InfiniteQueryData<int, int>, Exception>(QueryKey(['inf']));

      expect(query.data!.pages, [1]);
    });

    test('fetchNextPage appends data', () async {
      final cache = QueryCache();

      final observer = InfiniteQueryObserver<int, Exception, int>(
        cache: cache,
        queryKey: QueryKey(['inf']),
        queryFn: (page) async => page,
        initialPageParam: 1,
        getNextPageParam: (last, pages, lastParam, params) => lastParam + 1,
      );

      await observer.fetch();
      observer.fetchNextPage();
      await Future.delayed(Duration.zero);

      final query =
          cache.get<InfiniteQueryData<int, int>, Exception>(QueryKey(['inf']));

      expect(query.data!.pages, [1, 2]);
    });

    test('maxPages trims old pages', () async {
      final cache = QueryCache();

      final observer = InfiniteQueryObserver<int, Exception, int>(
        cache: cache,
        queryKey: QueryKey(['inf']),
        queryFn: (page) async => page,
        initialPageParam: 1,
        maxPages: 2,
        getNextPageParam: (last, pages, lastParam, params) => lastParam + 1,
      );

      await observer.fetch(); // [1]
      observer.fetchNextPage(); // [1,2]
      await Future.delayed(Duration.zero);

      observer.fetchNextPage(); // should trim to [2,3]
      await Future.delayed(Duration.zero);

      final query =
          cache.get<InfiniteQueryData<int, int>, Exception>(QueryKey(['inf']));

      expect(query.data!.pages, [2, 3]);
    });
  });
}

// simple helper class to test Observable mixin
class _TestObservable with Observable {}

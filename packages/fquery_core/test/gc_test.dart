import 'dart:async';
import 'package:test/test.dart';

import 'package:fquery_core/fquery_core.dart';

// TODO: use fake_async to test timers and intervals instead of relying on real time delays

void main() async {
  test('GC uses the longest cache duration of the lifetime', () async {
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

    await Future.delayed(Duration(milliseconds: 20));
    expect(cache.queries, isNotEmpty);

    await Future.delayed(Duration(milliseconds: 20));
    expect(cache.queries, isEmpty);
  });

  test('Notifications are scoped', () async {
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
    await Future.delayed(Duration(milliseconds: 10));

    // 1+1 because of `fetch` and `success` notifications from o1
    expect(count, equals(2));
  });

  test('Query initial state is sane', () async {
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

  test('Query fetch state is sane', () async {
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

  test('Query success state is sane', () async {
    final cache = QueryCache();

    final o1 = QueryObserver(
        cache: cache,
        queryKey: QueryKey(['q1']),
        queryFn: () async {
          await Future.delayed(Duration(milliseconds: 1));
          return 1;
        });

    final initialTimestamp = DateTime.now();
    o1.initialize();
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

  test('Query error state is sane', () async {
    final cache = QueryCache();

    final o1 = QueryObserver(
        cache: cache,
        queryKey: QueryKey(['q1']),
        retryCount: 0,
        queryFn: () async {
          await Future.delayed(Duration(milliseconds: 1));
          throw Exception('error');
        });

    final initialTimestamp = DateTime.now();
    o1.initialize();
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

  test('Refetches in specified intervals', () async {
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
    await Future.delayed(Duration(milliseconds: 50));

    expect(count, greaterThan(1));
  });

  test('Retries before giving up', () async {
    final cache = QueryCache();

    var count = 0;
    final o1 = QueryObserver(
        cache: cache,
        queryKey: QueryKey(['q1']),
        retryCount: 3,
        retryDelay: Duration(milliseconds: 0),
        queryFn: () {
          count++;
          throw Exception('error');
        });

    o1.initialize();
    await Future.delayed(Duration(milliseconds: 500));

    expect(count, equals(4));
  });

  test('Enable/disable side effects work', () async {
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
    await Future.delayed(Duration(milliseconds: 50));

    expect(count, equals(0));

    o1.updateOptions(
      QueryOptions(enabled: true, queryKey: o1.queryKey, queryFn: o1.queryFn),
    );

    await Future.delayed(Duration(milliseconds: 50));
    expect(count, equals(1));
  });

  test('Refetch interval changes are respected', () async {
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
    await Future.delayed(Duration(milliseconds: 50));

    expect(count, equals(1));

    o1.updateOptions(
      QueryOptions(
          refetchInterval: Duration(milliseconds: 10),
          queryKey: o1.queryKey,
          queryFn: o1.queryFn),
    );

    await Future.delayed(Duration(milliseconds: 50));
    expect(count, greaterThan(2));
  });

  test('Query is refetched when invalidated', () async {
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
    await Future.delayed(Duration(milliseconds: 50));

    expect(count, equals(1));

    cache.invalidateQueries(['q1']);

    await Future.delayed(Duration(milliseconds: 50));
    expect(count, equals(2));
  });
}

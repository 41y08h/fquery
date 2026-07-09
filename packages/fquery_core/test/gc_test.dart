import 'dart:async';
import 'package:test/test.dart';
import 'package:fake_async/fake_async.dart';

import 'package:fquery_core/fquery_core.dart';

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

  test('Refetch schedules successfully', () async {
    final cache = QueryCache();

    final o1 = QueryObserver(
        cache: cache,
        queryKey: QueryKey(['q1']),
        refetchInterval: Duration(milliseconds: 20),
        cacheDuration: null,
        queryFn: () {
          return Future.delayed(Duration(milliseconds: 1)).then((_) => 1);
        });

    o1.initialize();
    while (o1.query.dataUpdatedAt == null) {
      await Future.delayed(Duration.zero);
    }
    final firstUpdatedAt = o1.query.dataUpdatedAt;
    expect(firstUpdatedAt, isNotNull);

    await Future.delayed(Duration(milliseconds: 50));

    final secondUpdatedAt = o1.query.dataUpdatedAt;
    expect(secondUpdatedAt, isNotNull);
    expect(firstUpdatedAt!.isBefore(secondUpdatedAt!), isTrue);

    o1.dispose();
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
}

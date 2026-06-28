import 'dart:async';
import 'package:test/test.dart';

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
}

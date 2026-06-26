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
      cacheDuration: Duration(seconds: 1),
    );

    final secondObs = QueryObserver(
      cache: cache,
      queryKey: QueryKey(['gc']),
      queryFn: () {
        return 2;
      },
      cacheDuration: Duration(seconds: 3),
    );

    cache.dismantle(secondObs);
    cache.dismantle(firstObs);

    await Future.delayed(Duration(seconds: 2));
    expect(cache.queries, isNotEmpty);

    await Future.delayed(Duration(seconds: 2));
    expect(cache.queries, isEmpty);
  });
}

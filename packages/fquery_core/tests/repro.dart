import 'package:fquery_core/fquery_core.dart';

void main() async {
  final cache = QueryCache();

  final o1 =
      QueryObserver(cache: cache, queryKey: QueryKey(['q1']), queryFn: () => 1);

  final o2 =
      QueryObserver(cache: cache, queryKey: QueryKey(['q2']), queryFn: () => 2);

  o1.subscribe(1, () {
    print('notification from o1');
  });

  o2.subscribe(1, () {
    print('notification from o2');
  });

  o1.initialize();

  await Future.delayed(Duration(seconds: 2));
}

import 'dart:async';
import 'package:flutter_hooks/flutter_hooks.dart';

void usePeriodicTimer(
    Duration? interval, void Function() callback, List<Object>? keys) {
  useEffect(() {
    if (interval == null) return null;

    final timer = Timer.periodic(interval, (_) {
      callback();
    });
    return () => timer.cancel();
  }, [interval, ...(keys ?? [])]);
}

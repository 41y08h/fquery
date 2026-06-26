import 'dart:async';

import 'package:fquery_core/src/observer.dart';
import 'package:fquery_core/src/query.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'cache_map.freezed.dart';

@freezed
abstract class CacheMap with _$CacheMap {
  const CacheMap._();

  const factory CacheMap({
    @Default({}) Set<Observer> observers,
    Timer? gcTimer,
    required Duration cacheDuration,
    required Query query,
  }) = _CacheMap;
}

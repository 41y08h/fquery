import 'dart:async';
import 'dart:math';

import 'package:fquery/fquery.dart';

/// A mixin that provides functionality for removable objects with cache duration and garbage collection.
mixin Removable {
  Duration? _cacheDuration;
  Timer? _garbageCollectionTimer;

  /// Sets the cache duration
  /// Max cacheDuration given by any observer is used
  /// Reschedules the garbage collection timer
  void setCacheDuration(Duration cacheDuration) {
    _cacheDuration = Duration(
        milliseconds: max(
      (_cacheDuration ?? Duration.zero).inMilliseconds,
      cacheDuration.inMilliseconds,
    ));
    scheduleGarbageCollection();
  }

  /// This is called when garbage collection timer fires
  //  Defined by the child class
  void onGarbageCollection() {}

  /// Schedules the garbage collection timer
  void scheduleGarbageCollection() {
    print('garbage collection scheduled');
    _garbageCollectionTimer?.cancel();
    final duration = _cacheDuration ?? DefaultQueryOptions().cacheDuration;
    _garbageCollectionTimer = Timer(duration, onGarbageCollection);
  }

  /// Cancels the garbage collection timer
  void cancelGarbageCollection() {
    _garbageCollectionTimer?.cancel();
    _garbageCollectionTimer = null;
  }
}

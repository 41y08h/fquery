import 'dart:async';
import 'dart:math';

class Removable {
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

  void scheduleGarbageCollection() {
    _garbageCollectionTimer?.cancel();
    final duration = _cacheDuration ?? Duration(minutes: 5);
    _garbageCollectionTimer = Timer(duration, onGarbageCollection);
  }

  void cancelGarbageCollection() {
    _garbageCollectionTimer?.cancel();
    _garbageCollectionTimer = null;
  }
}

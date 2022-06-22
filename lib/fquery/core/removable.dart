import 'dart:async';

abstract class Removable {
  late Duration cacheTime;
  Timer? _gcTimer;

  void destroy() {
    clearGcTimer();
  }

  void scheduleGc() {
    clearGcTimer();

    _gcTimer = Timer(cacheTime, () {
      optionalRemove();
    });
  }

  void updateCacheTime(Duration cacheTime) {
    this.cacheTime = cacheTime;
  }

  void clearGcTimer() {
    _gcTimer?.cancel();
    _gcTimer = null;
  }

  void optionalRemove();
}
